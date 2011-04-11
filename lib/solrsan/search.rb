module Solrsan
  module Search
    extend ActiveSupport::Concern
    module ClassMethods

      HL_START_TAG = "<mark>"
      HL_END_TAG = "</mark>"

      def class_name
        to_s.underscore
      end
        
      def perform_solr_command
        @rsolr = Solrsan::Config.instance.rsolr_object
        yield(@rsolr)
        @rsolr.commit
      end

      def search(search_params={})
        @rsolr ||= Solrsan::Config.instance.rsolr_object

        start = search_params[:start] || 0
        rows = search_params[:rows] || 20

        solr_params = parse_params_for_solr(search_params)

        begin
          solr_response = @rsolr.paginate(start, rows, 'select', :params => solr_params)
          parse_solr_response(solr_response)
        rescue RSolr::Error::Http => e
          {:docs => [], 
           :metadata => 
            {:error => {:http_status_code => e.response[:status], 
                        :http_message_status => RSolr::Error::Http::STATUS_CODES[e.response[:status].to_i],
                        :full_message => e.message}}}
        end
      end

      def parse_params_for_solr(search_params={})
        solr_params = { :echoParams => 'explicit',
          :q => "*:*",
          :facet => "on",
          :'facet.mincount' => 1}.merge(search_params)
        solr_params[:hl] = true unless search_params[:'hl.fl'].blank?
        solr_params[:fq] = ["type:#{class_name}"] + parse_fq(search_params[:fq])
        solr_params
      end

      def parse_solr_response(solr_response)
        docs = solr_response['response']['docs']
        parsed_facet_counts = parse_facet_counts(solr_response['facet_counts'])
        highlighting = solr_response['highlighting']

        metadata = {
          :total_count => solr_response['response']['numFound'],
          :start => solr_response['response']['start'],
          :rows => solr_response['responseHeader']['params']['rows'],
          :time => solr_response['responseHeader']['QTime'],
          :status => solr_response['responseHeader']['status'],
          :sort => solr_response['responseHeader']['sort'],
          :debug => solr_response['debug']
        }
        response = {:docs => docs, :metadata =>  metadata,
         :facet_counts => parsed_facet_counts, :highlighting => highlighting}
        response[:stats] = solr_response['stats'] if solr_response['stats']

        embed_highlighting(response)
      end

      def parse_fq(fq)
        return [] if fq.nil?
        if fq.is_a?(Hash)
          fq.map{|k,v| parse_element_in_fq({k => v})}.flatten
        elsif fq.is_a?(Array)
          fq.map{|ele| parse_element_in_fq(ele)}.flatten
        else
          raise "fq must be a hash or array"
        end
      end

      def parse_element_in_fq(element)
        if element.is_a?(String)
          element
        elsif element.is_a?(Hash)
          element.map do |k,values|
            if values.is_a?(String)
              key_value_query(k,values)
            else
              values.map{|value| key_value_query(k,value) }
            end
          end
        else
          raise "each fq parameter must be a string or hash"
        end
      end

      def key_value_query(key, value)
        if value.starts_with?("[")
          "#{key}:#{value}"
        else
          "#{key}:\"#{value}\""
        end
      end

      def parse_facet_counts(facet_counts)
        return {} unless facet_counts
        
        if facet_counts['facet_fields']
          facet_counts['facet_fields'] = facet_counts['facet_fields'].reduce({}) do |acc, facet_collection|
            acc[facet_collection[0]] = map_facet_array_to_facet_hash(facet_collection[1])
            acc
          end
        end
  
        if facet_counts['facet_queries']
          facet_counts['facet_queries'] = facet_counts['facet_queries'].group_by{|k,v| k.split(":").first}.reduce({}) do |acc, facet_collection|
            facet_name = facet_collection[0]
            values = facet_collection[1]

            acc[facet_name] = values.reduce({}) do |inner_acc, tuple|
              range = tuple[0].split(":")[1]
              inner_acc[range] = tuple[1]
              inner_acc
            end
            acc
          end
        end

        facet_counts
      end
    
      # solr facet_fields comes in tuple array format []
      def map_facet_array_to_facet_hash(facet_collection)
        if facet_collection.is_a?(Array)
          facet_collection.each_slice(2).reduce({}){|acc, tuple| acc[tuple[0]] = tuple[1]; acc}
        else
          facet_collection
        end
      end

      def embed_highlighting(search_response)
        return search_response unless search_response[:highlighting]

        excluded_highlighting_fields = ['id', 'db_id', 'type']
        #save original pagniate keys
        per_page = search_response[:docs].per_page
        start = search_response[:docs].start
        total = search_response[:docs].total

        highlighted_docs = search_response[:docs].map do |doc|
          hl_metadata = search_response[:highlighting][doc['id']]

          hl_metadata.drop_while{|k,v| excluded_highlighting_fields.include?(k) }.each do |k,v|
            new_value = if doc[k].is_a?(Array)
              matched = v.map{|t| t.gsub(HL_START_TAG,"").gsub(HL_END_TAG,"") }
              v.concat(doc[k].drop_while{|text| matched.include?(text) })
            else
              v
            end
            doc[k] = new_value
          end if hl_metadata

          doc
        end

        search_response[:docs] = highlighted_docs

        search_response[:docs].extend RSolr::Pagination::PaginatedDocSet
        search_response[:docs].per_page = per_page
        search_response[:docs].start = start
        search_response[:docs].total = total

        search_response
      end

    end
  end
end

# namespace test documents
if defined?(Rails) && Rails.env == "test"
  module Solrsan
    module Search
      extend ActiveSupport::Concern
      module ClassMethods
        def class_name
          "#{to_s.underscore}_test"
        end
      end
    end
  end
end

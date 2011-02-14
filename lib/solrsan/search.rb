module Solrsan
  module Search
    extend ActiveSupport::Concern
    module ClassMethods
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
        { :echoParams => 'explicit',
          :fq => ["type:#{class_name}"],
          :q => "*:*",
          :facet => "on",
          :'facet.mincount' => 1}.merge(search_params)
      end

      def parse_solr_response(solr_response)
        docs = solr_response['response']['docs']
        parsed_facet_counts = parse_facet_counts(solr_response['facet_counts'])

        metadata = {
          :total_count => solr_response['response']['numFound'],
          :start => solr_response['response']['start'],
          :rows => solr_response['responseHeader']['params']['rows'],
          :time => solr_response['responseHeader']['QTime'],
          :status => solr_response['responseHeader']['status']
        }
        {:docs => docs, :metadata =>  metadata, :facet_counts => parsed_facet_counts}
      end

      def parse_facet_counts(facet_counts)
        facet_counts['facet_fields'] = facet_counts['facet_fields'].reduce({}) do |acc, facet_collection|
          acc[facet_collection[0]] = map_facet_array_to_facet_hash(facet_collection[1])
          acc
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

module Solrsan
  module Search
    extend ActiveSupport::Concern
    module ClassMethods
      @rsolr = Solrsan::Config.instance.rsolr_object
      
      def class_name
        to_s.downcase
      end
        
      def prefix
        "#{class_name}_"
      end

      def perform_solr_command
        @rsolr = Solrsan::Config.instance.rsolr_object
        yield(@rsolr)
        @rsolr.commit
      end

      def search(search_params={})
        raise "Could not connect to Solr" unless @rsolr

        solr_params = parse_params_for_solr(search_params)
        solr_response = @rsolr.find(solr_params)
        parse_solr_response(solr_response)
      end

      def autocomplete(ac_params={})
        [:field_name, :q].each do |required_field|
          if !ac_params[required_field]
            raise "Field name and term required for autocomplete. Missing #{required_field} parameter."
          end
        end

        #using direct http connection instead of Rsolr
        #tried cleaner @rsolr.request('terms', {:'terms.fl' => solr_field_name, :'terms.prefix' => term}) but didn't work
        solr_field_name = "#{prefix}#{ac_params[:field_name]}"
        term = ac_params[:q]
        #url = "#{Solrsan::Config.instance.solr_server_url}/terms?terms.fl=#{solr_field_name}&terms.prefix=#{term}&wt=json&omitHeader=true"

        res = Net::HTTP.get_response(URI.parse(url))
        results = JSON.parse(res.body)

        #use results["terms"][solr_field_name] when upgrading to solr 3.1
        results["terms"][1].each_slice(2).map {|name, matches| {'name' => name, 'matches' => matches}}
      end

      def parse_params_for_solr(search_params={})
        page_num_default = 1
        per_page_default = 20

        init_solr_params = {:q => search_params[:q].blank? ? "*:*" : search_params[:q],
                       :fq => ["type:#{class_name}"],
                       :page => search_params[:page]||page_num_default,
                       :per_page => search_params[:per_page]||per_page_default,
                       :rows => search_params[:per_page]||per_page_default,
                       :echoParams => 'explicit',
                       :qt => search_params[:qt],
                       :fl => search_params[:fl]}

        final_solr_params = prepend_prefixes(init_solr_params, search_params)
        
        final_solr_params
      end

      def prepend_prefixes(init_solr_params, search_params)
        facet_limit_default = 10
        solr_params = init_solr_params.clone

        ordered_facet_list = search_params[:'facets.fields']
        if ordered_facet_list
          prefixed_facet_list = ordered_facet_list.map{|facet| "#{prefix}#{facet}"}
          facet_params = {:facets => {:fields => prefixed_facet_list},
                          :'facet.limit' => search_params[:'facet.limit']||facet_limit_default}

          solr_params.merge!(facet_params)
        end

        facet_filters = search_params[:filters]
        if facet_filters
          new_facet_filters = {}
          #ensure terms are associated with the right field for search *especially if term has space
          facet_filters.reject{|k,v| v.blank?}.each do |k,v|
            new_value = if v.is_a?(Array)
              v.map{|v| "\"#{v}\""}
            elsif v.is_a?(String)
            # if the first char is '[', it's a range query so don't quote
              v.starts_with?("[") ? v : "\"#{v}\""
            end
          new_facet_filters["#{prefix}#{k}"] = new_value
          end
          solr_params[:filters] = new_facet_filters
        end

        if search_params[:sort]
          solr_params[:sort] = "#{prefix}#{search_params[:sort].strip}"
        end

        facet_queries = search_params[:'facet.query']
        if facet_queries
          solr_params[:'facet'] = 'on'
          solr_params[:'facet.query'] = facet_queries.map{|k| "#{prefix}#{k}"}
        end

        stats_fields = search_params[:'stats.field']
        if stats_fields
          solr_params[:stats] = 'on'
          solr_params[:'stats.field'] = stats_fields.map{|k| "#{prefix}#{k}"}
        end

        solr_params
      end

      def parse_solr_response(solr_response)
        rows = solr_response['responseHeader']['params']['rows'].to_i
        total_pages = solr_response['response']['numFound'].to_i / rows
        current_offset = solr_response['response']['start'].to_i

        pagination = paginate_page_numbers(current_offset, rows, total_pages)
        prefix_removed_docs = remove_prefix_from_array_of_hashes(prefix, solr_response.docs)
        prefix_removed_stats = remove_prefix_from_hash(prefix, solr_response['stats']['stats_fields']) rescue nil
        prefix_removed_facet_counts = remove_prefix_from_solr_facets(prefix, solr_response['facet_counts'])
        
        metadata = {
          :facet_counts => prefix_removed_facet_counts,
          :total_count => solr_response['response']['numFound'],
          :stats => prefix_removed_stats,
          :start => solr_response['response']['start'],
          :rows => solr_response['responseHeader']['params']['rows'],
          :time => solr_response['responseHeader']['QTime'],
          :previous_page => pagination[:previous_page],
          :current_page => pagination[:current_page],
          :next_page => pagination[:next_page],
          :status => solr_response['responseHeader']['status']
        }

        {:results => prefix_removed_docs, :metadata =>  metadata}
      end

      def remove_prefix_from_array_of_hashes(prefix, docs)
        docs.map{|doc| remove_prefix_from_hash(prefix, doc)}
      end

      def remove_prefix_from_hash(prefix, hash)
        new_hash = {}
        hash.each{|k,v| new_hash[k.to_s.gsub(/^#{prefix}/, "").to_sym] = v}
        new_hash
      end

      def remove_prefix_from_solr_facets(prefix, facet_counts)
        if facet_counts
          new_facet_counts =facet_counts.clone
          new_facet_counts[:facet_fields] = remove_prefix_from_hash(prefix, facet_counts[:facet_fields])
          new_facet_counts[:facet_queries] = remove_prefix_from_hash(prefix, facet_counts[:facet_queries])
          new_facet_counts
        else
          facet_counts
        end
      end

      def paginate_page_numbers(current_offset, rows, total_pages)
        current_page = (current_offset + rows) / rows
        previous_page = current_page - 1
        previous_page = nil if (previous_page <= 0)
        next_page = current_page + 1
        next_page = nil if (next_page > total_pages)

        {:current_page => current_page, :previous_page => previous_page, :next_page => next_page}
      end
    end
  end
end

module Solrsan
  module Search
    extend ActiveSupport::Concern
    module ClassMethods
      def class_name
        to_s.underscore
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
        @rsolr ||= Solrsan::Config.instance.rsolr_object

        solr_params = parse_params_for_solr(search_params)
        solr_response = @rsolr.get('select', :params => solr_params)
        parse_solr_response(solr_response)
      end

      def parse_params_for_solr(search_params={})
        page_num_default = 0
        per_page_default = 20
        
        start = search_params[:start]
        rows = search_params[:rows]

        { :echoParams => 'explicit',
          :fq => ["type:#{class_name}"],
          :q => "*:*"}.merge(search_params)
      end

      def parse_solr_response(solr_response)
        docs = solr_response['response']['docs']
        metadata = {
          :facet_counts => solr_response['response']['facets'],
          :total_count => solr_response['response']['numFound'],
          :start => solr_response['response']['start'],
          :rows => solr_response['responseHeader']['params']['rows'],
          :time => solr_response['responseHeader']['QTime'],
          :status => solr_response['responseHeader']['status']
        }
        {:docs => docs, :metadata =>  metadata}
      end
    end
  end
end

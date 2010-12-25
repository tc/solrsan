module Solrsan
  class Config
    include Singleton
    attr_accessor  :solr_server_url

    def rsolr_object
      @rsolr = RSolr.connect :url => @solr_server_url
    end
  end
end

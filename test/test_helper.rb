$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

#simulate rails env
class Rails
  def self.env
    "test"
  end
end

require "rubygems"
require "test/unit"
require 'solrsan'

#test models
require 'document'

solr_config = YAML::load( File.open( File.join(File.dirname(__FILE__), "..", "config", "solr.yml") ) )
solr_server_url = solr_config["test"]['solr_server_url']

Solrsan::Config.instance.solr_server_url = solr_server_url

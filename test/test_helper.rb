$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

require "rubygems"
require "test/unit"
require 'solrsan'

#test models
require 'document'

Solrsan::Config.instance.solr_server_url = "http://lh:9090/solr"

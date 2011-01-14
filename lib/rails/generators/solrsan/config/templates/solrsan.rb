solr_config = YAML::load( File.open( File.join(Rails.root, "config", "solr.yml") ) )
solr_server_url = solr_config[Rails.env]['solr_server_url']

Solrsan::Config.instance.solr_server_url = solr_server_url


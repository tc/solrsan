require 'uri'

namespace :solr do
  env =  "development"
  base_dir = File.join(File.dirname(__FILE__), "..", "..")

  if defined? Rails
    env = Rails.env
    base_dir = Rails.root
  end

  solr_config = YAML::load( File.open( File.join(base_dir, "config", "solr.yml") ) )
  solr_home = File.join(base_dir, "config", "solr")
  solr_data_dir = solr_config[env]['solr_data_dir']
  solr_server_url = solr_config[env]['solr_server_url']

  jetty_port = URI.parse(solr_server_url).port
  jetty_path = solr_config[env]['jetty_path']

  solr_server_dir = "cd #{jetty_path};"
  start_solr_cmd = "java -jar start.jar"
  solr_params = "-Djetty.port=#{jetty_port} -Dsolr.solr.home=#{solr_home} -Dsolr.data.dir=#{solr_data_dir}"

  desc "Start solr"
  task(:start) do
    # -Dsolr.clustering.enabled=true
    cmd = "#{solr_server_dir} #{start_solr_cmd } #{solr_params} &"
    puts cmd
    status = system(cmd)
    exit($?.exitstatus)
  end

  desc "Stop solr"
  task(:stop) do
    stop_solr_cmd = "echo `ps -ef | grep -v grep | grep \"#{solr_params.gsub("-", "\\-")}\" | awk '{print $2}'` | xargs -o kill"
    puts stop_solr_cmd
    status = system(stop_solr_cmd)
    exit($?.exitstatus)
  end

#  #example of a task to index all items
#  desc "index food"
#  task(:import_foods, :needs => :environment) do
#    FoodDescription.find_in_batches do |batch| 
#      FoodIndexer.index(batch)
#      puts "Done with batch of size: #{batch.size}"
#    end
#  end
end


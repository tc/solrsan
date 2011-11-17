require 'uri'
require 'erb'
require 'yaml'

namespace :solr do
  env =  "development"
  base_dir = File.join(File.dirname(__FILE__), "..", "..")

  if defined? Rails
    env = Rails.env
    base_dir = Rails.root
  end

  solr_config = YAML::load(ERB.new(IO.read(File.join(base_dir, 'config', 'solr.yml'))).result)
  solr_home = File.join(base_dir, "config", "solr")
  solr_data_dir = solr_config[env]['solr_data_dir']
  solr_server_url = solr_config[env]['solr_server_url']

  jetty_port = URI.parse(solr_server_url).port
  jetty_path = solr_config[env]['jetty_path']

  solr_server_dir = "cd \"#{jetty_path}\";"
  start_solr_cmd = "java -jar start.jar"
  logging_xml = "etc/jetty-logging.xml"
  jetty_port_opt = "jetty.port=#{jetty_port}"
  solr_params = "#{jetty_port_opt} -Dsolr.solr.home=\"#{solr_home}\" -Dsolr.data.dir=\"#{solr_data_dir}\""

  desc "Start solr"
  task(:start) do
    # -Dsolr.clustering.enabled=true
    cmd = kill_matching_process_cmd(jetty_port_opt)
    stop_exit_status = run_system_command(cmd)

    sleep(1)

    cmd = "#{solr_server_dir} #{start_solr_cmd} #{logging_xml} #{solr_params} &"
    run_system_command(cmd)
  end

  desc "Stop solr"
  task(:stop) do
    cmd = kill_matching_process_cmd(jetty_port_opt)
    run_system_command(cmd)
  end

  def run_system_command(cmd)
    puts cmd
    status = system(cmd)
    $?.exitstatus
  end

  def kill_matching_process_cmd(process_name)
      cmd = "echo `ps -ef | grep -v grep | grep \"#{process_name.gsub("-", "\\-")}\" | awk '{print $2}'` | xargs kill"
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


require 'rails/generators/solrsan_generator'

module Solrsan
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc "This setups the configuration files for solrsan"
      def self.source_root
        File.expand_path("../templates", __FILE__)
      end

      def create_config_files
        template "solrsan.rb", File.join("config", "initializers", "solrsan.rb")
        template "solr.yml", File.join("config", "solr.yml")
      end

      def copy_solr_conf
        Dir["config/solr/conf/*"].each do |source|
          destination = "config/solr/conf/#{File.basename(source)}"
          FileUtils.rm(destination) if options[:force]
          if File.exist?(destination)  
            puts "Skipping #{destination} because it already exists"
          else  
            puts "Generating #{destination}"
            FileUtils.cp(source, destination)
          end
        end
      end
    end
  end
end

require 'rails/generators/solrsan_generator'

module Solrsan
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_config_files
        template("solrsan.rb", File.join("config", "initializers", "solrsan.rb"))
        template("solr.yml", File.join("config", "solr.yml"))
      end

      def copy_solr_conf
        directory "../../../../../../config/solr", "config/solr", :recursive => true
      end

      def copy_rake_task
        copy_file "../../../../../tasks/solr.rake", "lib/tasks/solr.rake"
      end

    end
  end
end

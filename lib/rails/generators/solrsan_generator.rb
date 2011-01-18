require "rails/generators/named_base"

module Solrsan #:nodoc:
  module Generators #:nodoc:
    class Base < ::Rails::Generators::NamedBase #:nodoc:
      def self.source_root
        File.expand_path("../#{base_name}/#{generator_name}/templates", __FILE__)
      end
    end
  end
end

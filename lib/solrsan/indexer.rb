module Solrsan
  module Search
    extend ActiveSupport::Concern

    module InstanceMethods
      def as_solr_document
         @attributes
      end

      private
      def indexed_fields
         raise "Object has have a valid as_solr_document defined" if as_solr_document.nil?
         class_name = self.class.to_s.downcase

         doc = {:type => class_name}
         doc[:id] = "#{class_name}-#{self.attributes[:id].to_s}"

         prefixed = as_solr_document.reject{|k,v| k == :id}
         prefixed = prefixed.reduce({}) do |acc, tuple|
           value = tuple[1]
           value = value.to_time.utc.xmlschema if value.is_a?(Date) || value.is_a?(Time)
           acc["#{class_name}_#{tuple[0]}"] = value
           acc 
         end
         doc.merge(prefixed)
      end
    end

    module ClassMethods
      def index(doc)
        solr_docs = []
        if doc.respond_to?(:map)
          solr_docs = doc.map{|docment| as_solr_document(docment) }
        elsif doc.respond_to?(:as_solr_document)
          solr_docs << doc.indexed_fields
        else
          raise "Indexed document must define a as_solr_document method."
        end
        self.perform_solr_command do |rsolr|
          rsolr.add(solr_docs)
        end
      end

      def clear_search_index!
        self.perform_solr_command do |rsolr|
          rsolr.delete_by_query("type:#{class_name}")
        end
      end
    end
  end
end

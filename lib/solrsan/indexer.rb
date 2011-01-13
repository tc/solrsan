module Solrsan
  module Search
    extend ActiveSupport::Concern

    module InstanceMethods

      def as_solr_document
         self.attributes
      end

      def indexed_fields
        raise "Object has have a valid as_solr_document defined" if as_solr_document.nil?

        class_name = self.class.to_s.underscore
        doc = {:type => class_name, :db_id => id_value, :id => solr_id_value}

        initial_document_fields = as_solr_document.reject{|k,v| k == :id || k == :_id}
        converted_fields = initial_document_fields.reduce({}) do |acc, tuple|
          value = tuple[1]
          value = value.to_time.utc.xmlschema if value.is_a?(Date) || value.is_a?(Time)
          acc[tuple[0]] = value
          acc 
        end
        doc.merge(converted_fields)
      end

      def index
        self.class.index(self)
      end

      def destroy_index_document
        self.class.destroy_index_document(self)
      end

      def id_value
        item_id = self.attributes[:_id] || self.attributes[:id] || self.id
        raise "Object must have an id attribute defined before being indexed" if item_id.nil?
        item_id
      end

      def solr_id_value
        "#{self.class.to_s.underscore}-#{id_value.to_s}"
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

      def index_all
        self.find_in_batches(:batch_size => 100) do |group|
          self.index(group)
        end
      end

      def destroy_index_document(doc)
        if doc.respond_to?(:solr_id_value)
          self.perform_solr_command do |rsolr|
            rsolr.delete_by_query("id:#{doc.solr_id_value}")
          end
        else
          raise "Object must include Solrsan::Search"
        end
      end

      def destroy_all_index_documents!
        self.perform_solr_command do |rsolr|
          rsolr.delete_by_query("type:#{class_name}")
        end
      end
    end
  end
end

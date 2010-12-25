require 'active_model/attribute_methods'

class Document
  include ActiveModel::AttributeMethods
  include Solrsan::Search
  attr_accessor :attributes

  def initialize(attributes={})
    @attributes = attributes
  end
end

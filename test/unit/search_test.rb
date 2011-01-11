require 'test_helper'
require 'search_test_helper'

class SearchTest < Test::Unit::TestCase
  include SearchTestHelper

  def setup
    Document.clear_search_index!
    @document = document_mock
  end
  
  def teardown
    Document.clear_search_index!
  end

  def test_simple_query
    Document.index(@document)
    q = @document.attributes[:title]

    response = Document.search(:q => q)
    metadata = response[:metadata]
    docs = response[:docs]
    assert metadata[:total_count] > 0
  end

  def test_sort
    Document.index(Document.new(:id => 3, :title => "solar city",:review_count => 10))
    Document.index(Document.new(:id => 4, :title => "city solar", :review_count => 5))

    q = "solar"
    response = Document.search(:q => q, :sort => "review_count asc")
    docs = response[:docs]

    assert_not_nil docs[0], "Not enough docs for #{q} to test."
    first_result_name = docs[0][:title]
    assert_not_nil docs[1], "Not enough docs for #{q} to test."
    second_result_name = docs[1][:title]

    assert_equal [second_result_name, first_result_name].sort, [first_result_name, second_result_name]

    response = Document.search(:q => q, :sort => "review_count desc")
    docs = response[:docs]

    assert_not_nil docs[0], "Not enough docs for #{q} to test."
    first_result_name = docs[0][:title]
    assert_not_nil docs[1], "Not enough docs for #{q} to test."
    second_result_name = docs[1][:title]

    assert_equal [second_result_name, first_result_name].sort.reverse, [first_result_name, second_result_name]
  end

end


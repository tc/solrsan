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

    response = ::Document.search(:q => q)
    metadata = response[:metadata]
    results = response[:results]
    
    assert metadata[:total_count] > 0
  end

  def test_page_1_results_differ_from_page_2
    Document.index(Document.new(:id => 1, :title => "foo bar"))
    Document.index(Document.new(:id => 2, :title => "bar foo"))

    q = "foo"
    per_page = 1

    page_1_response = ::Document.search(:q => q,
                                                    :per_page => per_page)
    page_1_results = page_1_response[:results]
    first_page1_result = page_1_results.first

    page_2_response = ::Document.search(:q => q,
                                                    :per_page => per_page,
                                                    :page => 2)
    page_2_results = page_2_response[:results]
    first_page2_result = page_2_results.first
    
    assert_not_nil first_page1_result
    assert_not_nil first_page1_result[:title]
    assert_not_nil first_page2_result
    assert_not_nil first_page2_result[:title]
    assert_not_equal first_page1_result[:title], first_page2_result[:title]
  end

  def test_sort
    Document.index(Document.new(:id => 3, :title => "solar city",:review_count => 10))
    Document.index(Document.new(:id => 4, :title => "city solar", :review_count => 5))

    q = "solar"
    response = ::Document.search(:q => q, :sort => "review_count asc")
    results = response[:results]

    assert_not_nil results[0], "Not enough results for #{q} to test."
    first_result_name = results[0][:title]
    assert_not_nil results[1], "Not enough results for #{q} to test."
    second_result_name = results[1][:title]

    assert [second_result_name, first_result_name].sort, [first_result_name, second_result_name]

    response = ::Document.search(:q => q, :sort => "review_count desc")
    results = response[:results]

    assert_not_nil results[0], "Not enough results for #{q} to test."
    first_result_name = results[0][:title]
    assert_not_nil results[1], "Not enough results for #{q} to test."
    second_result_name = results[1][:title]

    assert [second_result_name, first_result_name].sort.reverse, [first_result_name, second_result_name]
  end

  def test_remove_prefix_from_solr_docs
    solr_docs = [{:document_title => "A", :document_review_count => 1},
                 {:document_title => "B", :document_review_count => 2}]

    removed_prefix_docs = ::Document.remove_prefix_from_array_of_hashes("document", solr_docs)

    all_keys = removed_prefix_docs.map{|d| d.keys}.flatten

    assert all_keys.find_all{|x| x.to_s.starts_with?("document")}.empty?
  end

end


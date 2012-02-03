require 'test_helper'
require 'search_test_helper'

class SearchTest < Test::Unit::TestCase
  include SearchTestHelper

  def setup
    Document.destroy_all_index_documents!
    @document = document_mock
  end
  
  def teardown
    Document.destroy_all_index_documents!
  end

  def test_attributes
    Document.solr_index(@document)
    sleep 1
    q = @document.attributes[:title]

    response = Document.search(:q => q)
    metadata = response[:metadata]
    docs = response[:docs]
    doc = docs.first

    assert_equal "document_test", doc["type"]
  end

  def test_simple_query
    Document.solr_index(@document)
    sleep 1
    q = @document.attributes[:title]

    response = Document.search(:q => q)
    metadata = response[:metadata]
    docs = response[:docs]
    assert metadata[:total_count] > 0
  end

  def test_sort
    Document.solr_index(Document.new(:id => 3, :title => "solar city",:review_count => 10))
    Document.solr_index(Document.new(:id => 4, :title => "city solar", :review_count => 5))
    sleep 1

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
  
  def test_invalid_query_should_return_error_message_in_metadata
    response = Document.search(:q => "http://tommy.chheng.com")
    docs = response[:docs]
    metadata = response[:metadata]

    assert_not_nil response[:metadata][:error]
    assert_equal 400, response[:metadata][:error][:http_status_code]
  end

  def test_parse_facet_fields
    facet_counts = {'facet_queries'=>{},
      'facet_fields' => {'language' => ["Scala", 2, "Ruby", 1, "Java", 0]},
      'facet_dates'=>{}}
    
    facet_counts = Document.parse_facet_counts(facet_counts)
    
    assert_equal ["Scala", "Ruby", "Java"], facet_counts['facet_fields']['language'].keys
  end

  def test_parse_facet_queries
    facet_counts = {"facet_queries"=>{"funding:[0 TO 5000000]"=>1, "funding:[10000000 TO 50000000]"=>0}, "facet_fields"=>{}, "facet_dates"=>{}}

    facet_counts = Document.parse_facet_counts(facet_counts)

    expected = {"funding"=>{"[0 TO 5000000]"=>1, "[10000000 TO 50000000]"=>0}}
    assert_equal expected, facet_counts['facet_queries']
  end
  
  def test_parse_fq_with_hash
    params = {:fq => {:tags => ["ruby", "scala"]}}
    filters = Document.parse_fq(params[:fq])

    expected = ["tags:\"ruby\"", "tags:\"scala\""]
    assert_equal expected, filters
  end

  def test_parse_fq_with_hash_multiple_entries
    params = {:fq => {:tags => ["ruby", "scala"], :author => "Bert"}}
    filters = Document.parse_fq(params[:fq])

    expected = ["tags:\"ruby\"", "tags:\"scala\"", "author:\"Bert\""]
    assert_equal expected, filters
  end

  def test_parse_fq_with_hash_array_args
    params = {:fq => [{:tags => ["ruby", "scala"]}]}
    filters = Document.parse_fq(params[:fq])

    expected = ["tags:\"ruby\"", "tags:\"scala\""]
    assert_equal expected, filters
  end

  def test_parse_fq_with_hash_string_args
    params = {:fq => [{:tags => "ruby"}]}
    filters = Document.parse_fq(params[:fq])

    expected = ["tags:\"ruby\""]
    assert_equal expected, filters
  end

  def test_parse_fq_with_string_args
    params = {:fq => ["tags:ruby"]}
    filters = Document.parse_fq(params[:fq])

    expected = ["tags:ruby"]
    assert_equal expected, filters
  end

  def test_parse_fq_with_empty
    filters = Document.parse_fq([])
    expected = []
    assert_equal expected, filters
  end


  def test_filter_query_mulitple_filters
    Document.solr_index(Document.new(:id => 3, :author => "Bert", :title => "solr lucene",:review_count => 10, :tags => ['ruby']))
    Document.solr_index(Document.new(:id => 4, :author => "Ernie", :title => "lucene solr", :review_count => 5, :tags => ['ruby', 'scala']))
    sleep 1

    response = Document.search(:q => "solr", :fq => {:tags => ["scala"], :author => "Ernie"})
    docs = response[:docs]
    metadata = response[:metadata]

    assert_equal 1, metadata[:total_count]

    doc = docs.first
    assert_not_nil doc['tags']
    assert doc['tags'].include?("scala")
  end

  def test_filter_query
    Document.solr_index(Document.new(:id => 3, :author => "Bert", :title => "solr lucene",:review_count => 10, :tags => ['ruby']))
    Document.solr_index(Document.new(:id => 4, :author => "Ernie", :title => "lucene solr", :review_count => 5, :tags => ['ruby', 'scala']))
    sleep 1
    
    response = Document.search(:q => "solr", :fq => [{:tags => ["scala"]}])
    docs = response[:docs]
    metadata = response[:metadata]

    assert_equal 1, metadata[:total_count]

    doc = docs.first
    assert_not_nil doc['tags']
    assert doc['tags'].include?("scala")
  end

  def test_text_faceting
    Document.solr_index(Document.new(:id => 3, :author => "Bert", :title => "solr lucene",:review_count => 10))
    Document.solr_index(Document.new(:id => 4, :author => "Ernie", :title => "lucene solr", :review_count => 5))
    sleep 1
    
    response = Document.search(:q => "solr", :'facet.field' => ['author'])
    docs = response[:docs]
    facet_counts = response[:facet_counts]
    assert_not_nil facet_counts["facet_fields"]["author"]

    author_facet_entries = facet_counts["facet_fields"]["author"]
    assert author_facet_entries.keys.include?("Bert") && author_facet_entries.keys.include?("Ernie")
  end

  def test_range_faceting
    Document.solr_index(Document.new(:id => 3, :author => "Bert", :title => "solr lucene",:review_count => 10))
    Document.solr_index(Document.new(:id => 4, :author => "Ernie", :title => "lucene solr", :review_count => 5))
    sleep 1

    response = Document.search(:q => "solr", :'facet.field' => ['author'], :'facet.query' => ["review_count:[1 TO 5]", "review_count:[6 TO 10]"])
    docs = response[:docs]
    facet_counts = response[:facet_counts]

    assert_not_nil facet_counts["facet_fields"]["author"]
    assert_not_nil facet_counts["facet_queries"]["review_count"]
    assert_equal({"[1 TO 5]"=>1, "[6 TO 10]"=>1}, facet_counts["facet_queries"]["review_count"])
  end

  def test_highlighting_support
    Document.solr_index(Document.new(:id => 3, :author => "Bert", :title => "solr lucene",:review_count => 10, :tags => ["solr"]))
    sleep 1

    response = Document.search(:q => "solr", 
                               :'hl.fl' => "*")
    docs = response[:docs]
    highlighting = response[:highlighting]

    first_result = highlighting.first
    assert_not_nil first_result
    assert first_result[1]['tags'].include?("<mark>solr</mark>")
  end

  def test_embed_highlighting
    Document.solr_index(Document.new(:id => 3, :author => "Bert", :title => "solr lucene",:review_count => 10, :tags => ["solr", "sphinx"]))
    sleep 1

    response = Document.search(:q => "solr", 
                               :'hl.fl' => "*")
    docs = response[:docs]
    assert_not_nil docs.first
    assert_equal ["<mark>solr</mark>","sphinx"], docs.first['tags']
  end

  def test_debug_response
    Document.solr_index(@document)
    sleep 1
    q = @document.attributes[:title]

    response = Document.search({:q => q, :debugQuery => true})
    metadata = response[:metadata]
    assert_not_nil metadata[:debug]
  end

  def test_stats_response
    Document.solr_index(@document)
    sleep 1
    q = @document.attributes[:title]

    response = Document.search({:q => q, :stats => true, :'stats.field' => 'review_count'})
    assert_not_nil response[:stats]
    assert_not_nil response[:stats]['stats_fields']['review_count']
    assert_equal 1, response[:stats]['stats_fields']['review_count']['count']
  end

  def test_will_paginate_support
    Document.solr_index(Document.new(:id => 3, :author => "Bert", :title => "solr lucene",:review_count => 10))
    Document.solr_index(Document.new(:id => 4, :author => "Ernie", :title => "lucene solr", :review_count => 5))
    sleep 1
    
    response = Document.search(:q => "solr")
    docs = response[:docs]
    assert_not_nil docs.start
    assert_not_nil docs.per_page
    assert_not_nil docs.current_page
  end
end

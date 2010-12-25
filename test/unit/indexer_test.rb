require 'test_helper'
require 'search_test_helper'

class IndexerTest < Test::Unit::TestCase
  include SearchTestHelper

  def setup
    @document = document_mock
  end

  def teardown
  end

  def test_as_solr_document
    created_doc = @document.as_solr_document
    assert_equal @document.attributes[:title], created_doc[prepend_prefix('title')]
    assert_equal @document.attributes[:author], created_doc[prepend_prefix('author')]
    assert_equal @document.attributes[:content], created_doc[prepend_prefix('content')]
    assert_equal @document.attributes[:review_count], created_doc[prepend_prefix('review_count')]
    assert_equal @document.attributes[:scores], created_doc[prepend_prefix('scores')]
    assert_equal @document.attributes[:created_at].to_time.utc.xmlschema, created_doc[prepend_prefix('created_at')]
  end

  def prepend_prefix(name)
    "document_#{name}"
  end
end

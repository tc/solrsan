require 'test_helper'
require 'search_test_helper'

class IndexerTest < Test::Unit::TestCase
  include SearchTestHelper

  def setup
    @document = document_mock
  end

  def teardown
  end

  def test_indexed_fields
    created_doc = @document.indexed_fields
    assert_equal @document.attributes[:title], created_doc[:title]
    assert_equal @document.attributes[:author], created_doc[:author]
    assert_equal @document.attributes[:content], created_doc[:content]
    assert_equal @document.attributes[:review_count], created_doc[:review_count]
    assert_equal @document.attributes[:scores], created_doc[:scores]
    assert_equal @document.attributes[:created_at].to_time.utc.xmlschema, created_doc[:created_at]
  end

end

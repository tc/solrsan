module SearchTestHelper
  def document_mock
    doc = Document.new({:id => 500,
    :title => "Solr test document",
    :author => "Tommy Chheng",
    :content => "ruby scala search",
    :review_count => 4,
    :scores => [1,2,3,4],
    :created_at => Date.parse("Dec 10 2010")})
    doc
  end
end


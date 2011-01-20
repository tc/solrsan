# solrsan
This gem is a lightweight wrapper for the Apache Solr API.

Before you start, read the documentation for solr at http://wiki.apache.org/solr/

It'll be invaluable for knowing parameters and error messages. I made a few test cases for further examples at http://github.com/tc/solrsan/tree/master/test/

## HOWTO
Install jetty:
Download jetty 7 from http://download.eclipse.org/jetty/stable-7/dist/

Install solr:
Download solr from http://www.apache.org/dyn/closer.cgi/lucene/solr/
Unzip the jar file:
tar -zxvf apache-solr-*.jar

Copy dist/apache-solr-*.war into jetty's webapps directory as solr.war:
cd apache-solr-*
cp dist/apache-solr-*.war JETTY_PATH/webapps/solr.war

Create solrsan and solr configuration files using:
  rails generate Solrsan:Config

The generator will copy the following files into your application.
  config/solr.yml
  config/solr
  config/initializers/solrsan.rb
  lib/tasks/solr.rake

##
The fields are required for each solr document:
id, db_id, type

In each model, you can include a Solrsan::Search module which will include a few interface helper methods:
index
destroy_index_document
search(params)

You can also add hooks for thse methods:
class Document < ActiveRecord::Base
  include Solrsan::Search
  after_save :index
  before_destroy :destroy_index_document
end

---
## Changelog
0.0.1
First release.

## Copyright

Copyright (c) 2011 Tommy Chheng. See LICENSE for details.


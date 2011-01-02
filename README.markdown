# solrsan
This gem is a lightweight wrapper for the Apache Solr API.

Before you start, read the documentation for solr at http://wiki.apache.org/solr/

It'll be invaluable for knowing parameters and error messages. The gem keeps the request/response as hashes so you will have to
read the manual to make the proper calls. I made a few test cases for further examples at http://github.com/tc/solrgen/tree/master/test/


## HOWTO
Install jetty and solr:
Download jetty
Download solr
Place the solr.war file into the jetty's webapps directory.

Create solr.yml to your config folder:
defaults: &defaults
  jetty_path: "/Users/tcc/Sites/java/jetty"
  solr_data_dir: "/Users/tcc/src/eat2treat/eat2treat-search-index"
  solr_server_url: "http://localhost:9090/solr"
development:
  <<: *defaults
test:
  <<: *defaults
production:
  jetty_path: "/usr/local/jetty"
  solr_data_dir: "/data/solr/eat2treat-data"
  solr_server_url: "http://localhost:8080/solr"

Make the search request:

---
## Changelog
0.0.1
First release.

## Copyright

Copyright (c) 2011 Tommy Chheng. See LICENSE for details.


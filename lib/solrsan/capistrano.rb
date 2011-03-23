# add require 'solrsan/capistrano', be sure to have solr.rake in your tasks dir

Capistrano::Configuration.instance(:must_exist).load do
  namespace :solr do
    desc "starts solr"
    task :start, :roles => :search do
      run "cd #{current_path} && rake solr:start RAILS_ENV=#{stage}"
    end

    desc "stops solr"
    task :stop, :roles => :search do
      run "cd #{current_path} && rake solr:stop RAILS_ENV=#{stage}"
    end

    desc "clear and re-index"
    task :reindex, :roles => :search do
      run "cd #{current_path} && rake solr:clear_index RAILS_ENV=#{stage}"
      run "cd #{current_path} && rake solr:index RAILS_ENV=#{stage}"
    end
  end
end

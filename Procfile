web: bundle exec rackup config.ru -p $PORT
worker: TERM_CHILD=1 QUEUE=* bundle exec rake resque:work

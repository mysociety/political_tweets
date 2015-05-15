workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

port ENV['PORT'] || 9292

on_worker_boot do
  Sequel.connect(ENV['DATABASE_URL'])
  Resque.redis = ENV['REDISTOGO_URL']
end

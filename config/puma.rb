workers Integer(ENV['PUMA_WORKERS'] || 3)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 16)

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

lowlevel_error_handler do |ex, env|
  Raven.capture_exception(
    ex,
    :message => ex.message,
    :extra => { :puma => env },
    :culprit => "Puma"
  )
  [500, {}, ["An error has occurred, and engineers have been informed.\n"]]
end

on_worker_boot do
  DB.disconnect
end

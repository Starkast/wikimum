require 'bundler'

Bundler.require

Dir['./tasks/*.rake'].each { |f| load f }

task :environment do
  require './config/environment'
  require './lib/models'
end

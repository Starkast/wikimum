require 'bundler/setup'
Dir['./tasks/*.rake'].each { |f| load f }

task :environment do
  require './config/environment'
  require './lib/models'
end

begin
  desc 'Interactive console'
  task :console do
    exec 'irb -r ./config/environment -r ./lib/models'
  end
end

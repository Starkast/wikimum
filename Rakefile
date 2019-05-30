# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'

Dir['tasks/*.rake'].each { |f| load f }

task default: [:test]
task test: ['test:unit', 'test:integration', 'rubocop']

RuboCop::RakeTask.new

namespace(:test) do
  Rake::TestTask.new(:integration) do |t|
    t.pattern = "test/integration/*_test.rb"
  end

  Rake::TestTask.new(:unit) do |t|
    t.pattern = "test/unit/*_test.rb"
  end
end

namespace(:db) do
  desc "Replace local database with production database"
  task :pull do |t|
    require "uri"
    uri = URI.parse(ENV.fetch("DATABASE_URL"))
    local_database = uri.path[1..-1]

    trap("INT") { exit }

    puts "Will remove local database '#{local_database}', press Enter to proceed, ^C to abort"
    STDIN.gets

    system "dropdb #{local_database}"
    system "heroku pg:pull DATABASE_URL #{local_database}"
  end

  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require 'sequel'
    Sequel.extension(:migration)
    db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, 'migrations', target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, 'migrations')
    end
  end
end

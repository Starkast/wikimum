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
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require 'sequel'
    require_relative 'config/database' # creates DB

    Sequel.extension(:migration)

    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(DB, 'migrations', target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(DB, 'migrations')
    end
  end
end

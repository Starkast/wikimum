# frozen_string_literal: true

require 'bundler/setup'
require 'rake/testtask'
require 'rubocop/rake_task'

Dir['tasks/*.rake'].each { |f| load f }

task default: [:test]
task test: ['test:unit', 'test:integration', 'test:javascript', 'rubocop']

RuboCop::RakeTask.new

namespace(:test) do
  Rake::TestTask.new(:integration) do |t|
    t.pattern = "test/integration/*_test.rb"
  end

  Rake::TestTask.new(:unit) do |t|
    t.pattern = "test/unit/*_test.rb"
  end

  desc "Run JavaScript tests (requires Node.js)"
  task :javascript do
    if system('which node > /dev/null 2>&1')
      sh 'node --test test/javascript/*_test.js'
    else
      puts "Skipping JavaScript tests (Node.js not available)"
    end
  end

  desc "Run browser tests (requires running server, Chromium, and puppeteer-core)"
  task :browser do
    test_url = ENV.fetch('TEST_URL', 'http://localhost:9393')
    if system('which node > /dev/null 2>&1') && system('which chromium > /dev/null 2>&1')
      sh "TEST_URL=#{test_url} node --test test/browser/*_test.js"
    else
      puts "Skipping browser tests (Node.js or Chromium not available)"
    end
  end
end

namespace(:db) do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require 'sequel'
    Sequel.extension(:migration)
    db = Sequel.connect(ENV.fetch('DATABASE_URL', 'postgres://localhost/wikimum'))
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, 'migrations', target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, 'migrations')
    end
  end
end

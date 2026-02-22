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

  desc "Run browser tests (requires Chromium and puppeteer-core)"
  task :browser do
    unless system('which node > /dev/null 2>&1') && system('which chromium > /dev/null 2>&1')
      puts "Skipping browser tests (Node.js or Chromium not available)"
      next
    end

    require 'net/http'
    require 'securerandom'
    require_relative 'test/test_database'

    test_port = ENV.fetch('TEST_PORT', '9393')
    test_url = ENV.fetch('TEST_URL', "http://localhost:#{test_port}")

    # Set up test database
    database_url = TestDatabase.create('wikimum_browser_test')
    session_secret = SecureRandom.hex(32)

    ENV['DATABASE_URL'] = database_url
    TestDatabase.migrate

    # Start the server
    puts "Starting server on port #{test_port}..."
    env = {
      'PORT' => test_port,
      'RACK_ENV' => 'test',
      'DATABASE_URL' => database_url,
      'SESSION_SECRET' => session_secret,
      'PUMA_LOG_REQUESTS' => '0'
    }
    pid = spawn(env, 'bundle', 'exec', 'puma', '--config', 'config/puma.rb',
                [:out, :err] => '/dev/null')

    # Wait for server to be ready
    uri = URI(test_url)
    30.times do
      begin
        Net::HTTP.get_response(uri)
        break
      rescue Errno::ECONNREFUSED
        sleep 0.1
      end
    end

    begin
      sh "TEST_URL=#{test_url} node --test test/browser/*_test.js"
    ensure
      puts "Stopping server..."
      Process.kill('TERM', pid)
      Process.wait(pid)
      TestDatabase.disconnect_and_drop('wikimum_browser_test')
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

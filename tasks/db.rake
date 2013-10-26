namespace :db do
  desc 'Apply all migrations'
  task :migrate do |task|
    check_for_param('DATABASE_URL', task)
    db_url = ENV['DATABASE_URL']
    run "sequel -E -m ./migrations #{db_url}"
  end

  namespace :migrate do
    desc 'Migrate down all migrations'
    task :downall do |task|
      check_for_param('DATABASE_URL', task)
      db_url = ENV['DATABASE_URL']
      run "sequel -E -m ./migrations -M 0 #{db_url}"
    end

    desc 'Migrate down to given migration'
    task :down do |task|
      check_for_param('DATABASE_URL', task)
      check_for_param('version', task)
      db_url = ENV['DATABASE_URL']
      run "sequel -E -m ./migrations -M #{ENV['version']} #{db_url}"
    end
  end
end

def run(command)
  result = `#{command}`
  if $?.exitstatus != 0
    raise StandardError, result
  end
  $stdout.puts result
end

def check_for_param(param, task)
  if ENV[param].nil?
    $stderr.puts <<-EOS

You have to run this task with the parameter '#{param}' set.

Example:

  foreman run rake #{task.name} #{param}=foo

    EOS
    exit 1
  end
end

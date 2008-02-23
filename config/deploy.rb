# This defines a deployment "recipe" that you can feed to switchtower
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

# The application name
set :application, "wikimum"
set :repository, "svn+ssh://genau.jage.se/export/storage/imum/svn/imum-site/trunk"

# Everything is running as my use
set :use_sudo, false

# One server for everything
role :web, "hera.jage.se"
role :app, "hera.jage.se"
role :db,  "genau.jage.se", :primary => true

# Were the application lives
set :deploy_to, "/var/www/users/jage/wikimum"

# =============================================================================
# TASKS
# =============================================================================

desc "Start the spinner daemon"
task :spinner, :roles => :app do
  run "#{current_path}/script/spin"
end

desc "Restart Ruby-processes"
task :restart, :roles => :app do
  run "#{current_path}/script/process/reaper"
end

desc "Show a maintenance screen for all requests"
task :disable_web do
  # Read in the file and make sure the variables are available
  maintenance = render('config/templates/maintenance', :until => ENV['UNTIL'], :reason => ENV['REASON'])
  # Send the file to the server
  put maintenance, "#{shared_path}/system/maintenance.html", :mode => 0644

  on_rollbak do
    delete "#{shared_path}/system/maintenance.html"
  end
end

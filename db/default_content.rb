#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/environment'

puts "Creating default user"
u = User.create(:login => 'admin',
                :name => 'Administrator',
                :password => 'wikimum',
                :password_confirmation => 'wikimum',
                :email => 'wiki@imum.net')
u.admin = true
u.new_password = true
u.save

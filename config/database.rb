# frozen_string_literal: true

database_dir  = ENV.fetch("DATABASE_DIR",  "./storage")
database_name = ENV.fetch("DATABASE_NAME", "wiki")

DB = Sequel.connect("sqlite://#{database_dir}/#{database_name}.db")

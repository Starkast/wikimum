# frozen_string_literal: true

database_url = ENV.fetch("DATABASE_URL", "sqlite://storage/wiki.db")
DB = Sequel.connect(database_url)

# frozen_string_literal: true

database_url = ENV.fetch("DATABASE_URL", "sqlite://storage/wiki.db")
DB = Sequel.connect(database_url)

# https://github.com/Starkast/wikimum/issues/412
# https://sequel.jeremyevans.net/rdoc-plugins/files/lib/sequel/extensions/connection_validator_rb.html
DB.extension(:connection_validator)
DB.pool.connection_validation_timeout = 60 * 5

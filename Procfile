web: bundle exec puma -C config/puma.rb
development: bundle exec puma -b tcp://localhost:$(($PORT-100)) -b ssl://localhost:$(($PORT-100-1000))
testprod: bundle exec puma -b tcp://localhost:$(($PORT-100)) -b ssl://localhost:$(($PORT-100-1000))

# Wikimum

[![Build Status](https://travis-ci.org/Starkast/wikimum.svg?branch=master)](https://travis-ci.org/Starkast/wikimum)
[![Code Climate](https://codeclimate.com/github/Starkast/wikimum/badges/gpa.svg)](https://codeclimate.com/github/Starkast/wikimum)

Next Generation Wikimum!

_This application is under active development and should not be used in production yet_.

## Development

These instructions assume you are using OS X.

Install prerequisites

    brew install postgresql
    brew install cmake
    bundle install

Ruby gems are vendored into `vendor/cache`, you should always check in the gems when changing gems. The caching is set up with [`bundle package --all`](https://bundler.io/man/bundle-package.1.html).

### Database setup

Make sure PostgreSQL is running

    postgres

Get a copy of the production database

    dotenv rake db:pull

### Start the app

    foreman start

Go to [http://wikimum.127.0.0.1.nip.io:8080](http://wikimum.127.0.0.1.nip.io:8080) (the GitHub app for development is configured with this address).

### Environment variables

```
# Development and production
DATABASE_URL=postgres://
GITHUB_BASIC_CLIENT_ID=
GITHUB_BASIC_SECRET_ID=
# Production
SESSION_SECRET=
SENTRY_DSN=
```

### Console

    foreman run bundle exec racksh

### Tests

    bundle exec rake

### [Migrations][sequel-migrations]

To migrate to the latest version, run:

    bin/dev_db_bootstrap

This Rake task takes an optional argument specifying the target version. To migrate to version 42, run:

    bundle exec rake db:migrate[42]

Manually:

    sequel -E -m migrations -M <n> postgres://localhost/wikimum

[sequel-migrations]: http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html

## History

This wiki software was originally developed by [Johan Eckerström](http://github.com/jage) at IMUM HB back in 2005. When we killed the company the software was kept running at [Starkast](http://wiki.starkast.net/) but not much work was done on it. Originally a Rails (1.x) app, it's now a Sinatra based application.

## License

MIT License, see [LICENSE](LICENSE).

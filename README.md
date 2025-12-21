# Wikimum

[![GitHub Build Status](https://github.com/Starkast/wikimum/workflows/CI/badge.svg)](https://github.com/Starkast/wikimum/actions)
[![Code Climate](https://codeclimate.com/github/Starkast/wikimum/badges/gpa.svg)](https://codeclimate.com/github/Starkast/wikimum)

Next Generation Wikimum!

_This application is under active development and should not be used in production yet_.

## Development

These instructions assume you are using OS X.

Install prerequisites

    brew install postgresql
    gem install overman
    bundle install

Ruby gems are vendored into `vendor/cache`, you should always check in the gems when changing gems. The caching is set up with [`bundle package --all`](https://bundler.io/man/bundle-package.1.html).

### Database setup

Make sure PostgreSQL is running

    postgres

#### Import production database

    dotenv bin/download_database_backup
    createdb prod-wikimum
    psql postgres://localhost/prod-wikimum < starkast_wiki_backup_2024-06-15_215012.sql

### Start the app

In production, the script `bin/start` is used, but we avoid using that in the `Procfile` because the integration tests reads that command and needs to get the PID of Puma, not the script, in order to cleanly shutdown Puma.

    bin/dev

Go to [http://wikimum.127.0.0.1.nip.io:8080](http://wikimum.127.0.0.1.nip.io:8080) (the GitHub app for development is configured with this address).

### Environment variables

```bash
# Development and production
DATABASE_URL=postgres://
GITHUB_BASIC_CLIENT_ID=
GITHUB_BASIC_SECRET_ID=
BACKUP_USER=
BACKUP_PASSWORD=
PGGSSENCMODE=disable # https://github.com/ged/ruby-pg/issues/311#issuecomment-1609970533
SESSION_SECRET= # generate with: ruby -rsecurerandom -e 'p SecureRandom.hex(32)'
# Production
SENTRY_DSN=
# Development
REDIRECT_TO_HTTPS=1 # redirect http:// to https://
# Tests
DEBUG=1 # enable debug output from tests that have it
# Set app in maintenance mode
MAINTENANCE_MODE=true
```

### Console

    overman run bundle exec racksh

### Tests

    bundle exec rake

Run single test with [`m`](https://github.com/qrush/m):

    bundle exec m test/integration/app_boot_test.rb:29

### [Migrations][sequel-migrations]

To migrate to the latest version, run:

    bin/dev_db_bootstrap

This Rake task takes an optional argument specifying the target version. To migrate to version 42, run:

    bundle exec rake db:migrate[42]

Manually:

    sequel -E -m migrations -M <n> postgres://localhost/wikimum

## Deployment

### Production

_TODO_

### Preview

Fly.io app `wikimum-preview` exist to test changes before production. It can be reached at https://wikimum-preview.fly.dev/

The first deploy was manual:

```bash
flyctl deploy --ha=false --build-arg "RUBY_VERSION=$(cat .ruby-version)" --app=wikimum-preview
```

The preview app uses a PostgreSQL database from Aiven, deployed in AWS eu-north-1.

These are the secrets configured:

```bash
fly secrets set --detach --app wikimum-preview DATABASE_URL="$(pbpaste)"
fly secrets set --detach --app wikimum-preview SESSION_SECRET="$(pbpaste)"
```

To keep the preview database (at Aiven) from being removed prematurely, GitHub Actions has been configured with the `cron.yml` workflow and this secret:

```bash
gh secret --repo Starkast/wikimum set PREVIEW_DATABASE_URL --body "$(pbpaste)"
```

## Code Scanning

GitHub Actions scan the code using [Brakeman](https://github.com/presidentbeef/brakeman).

If you need to ignore a weakness reported, update `config/brakeman.ignore`. You can get the JSON needed by running Brakeman like this:

```bash
docker run -it --rm -v $(pwd):/app -w /app ruby:$(cat .ruby-version) bash
gem install brakeman
brakeman --force --format json .
```

Don't forget to add a `note` attribute to the JSON object when ignoring.

[sequel-migrations]: http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html

## History

This wiki software was originally developed by [Johan Eckerström](http://github.com/jage) at IMUM HB back in 2005. When we killed the company the software was kept running at [Starkast](http://wiki.starkast.net/) but not much work was done on it. Originally a Rails (1.x) app, it's now a Sinatra based application.

## License

MIT License, see [LICENSE](LICENSE).

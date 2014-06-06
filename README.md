# Wikimum

Next Generation Wikimum!

## Development

_This application is under active development and should not be used in production yet_

    bundle install
    bundle exec unicorn -c ./config/unicorn.rb

### Environment variables

```
DATABASE_URL=postgres://
GITHUB_BASIC_CLIENT_ID=
GITHUB_BASIC_SECRET_ID=
SESSION_SECRET= # optional in development mode
```

### Console

    bundle exec racksh

### [Migrations][sequel-migrations]

To migrate to the latest version, run:

    rake db:migrate

This Rake task takes an optional argument specifying the target version. To migrate to version 42, run:

    rake db:migrate[42]

Manually:

    sequel -E -m migrations -M <n> postgres://localhost/wikimum

Pull database from Heroku:

    heroku pg:pull DATABASE_URL wikimum

[sequel-migrations]: http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html

## History

This wiki software was originally developed by [Johan Eckerström](http://github.com/jage) at IMUM HB back in 2005. When we killed the company the software was kept running at [Starkast](http://wiki.starkast.net/) but not much work was done on it. Originally a Rails (1.x) app, it's now a Sinatra based application.

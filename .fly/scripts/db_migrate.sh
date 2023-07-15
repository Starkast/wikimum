#!/bin/sh

# https://fly.io/docs/laravel/the-basics/customizing-deployments/#startup-scripts
#
# Since https://github.com/Starkast/wikimum/issues/506 "release_command" is not used
# https://fly.io/docs/reference/configuration/#run-one-off-commands-before-releasing-a-deployment

set -e
set -u

bundle exec rake db:migrate

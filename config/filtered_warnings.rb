# frozen_string_literal: true

require "warning"

# See https://github.com/jeremyevans/ruby-warning#usage--
ignores = %i[
  method_redefined
  mismatched_indentations
  missing_ivar
  not_reached
  shadow
  unused_var
] # this list is sorted alphabetically

# TODO: add :default_gem_removal when this PR is release (warning >1.4.0)
# https://github.com/jeremyevans/ruby-warning/pull/24

Gem.path.each do |path|
  Warning.ignore(ignores, path)
end

$VERBOSE = true

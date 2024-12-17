# frozen_string_literal: true

require "warning"

# See https://github.com/jeremyevans/ruby-warning#usage--
ignores = %i[
  method_redefined
  missing_ivar
  not_reached
  shadow
] # this list is sorted alphabetically

Gem.path.each do |path|
  Warning.ignore(ignores, path)
end

$VERBOSE = true

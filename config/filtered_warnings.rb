# frozen_string_literal: true

require "warning"

# See https://github.com/jeremyevans/ruby-warning#usage--
ignores = %i[
  default_gem_removal
  method_redefined
  mismatched_indentations
  missing_ivar
  not_reached
  shadow
  unused_var
] # this list is sorted alphabetically

Gem.path.each do |path|
  Warning.ignore(ignores, path)
end

$VERBOSE = true

# default_gem_removal
#
#   github-markup-5.0.1/lib/github/markup/rdoc.rb:2:
#   warning: rdoc was loaded from the standard library, but will no longer be
#   part of the default gems starting from Ruby 3.5.0

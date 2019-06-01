# frozen_string_literal: true

require "warning"

Gem.path.each do |path|
  Warning.ignore([:missing_ivar, :method_redefined, :shadow, :not_reached], path)
end

$VERBOSE = true
  

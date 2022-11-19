# frozen_string_literal: true

class MaintenanceModeApp
  def initialize(app)
    @app = app
  end

  def call(env)
    [503, {}, ["Offline for maintenance"]]
  end
end

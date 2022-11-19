# frozen_string_literal: true

class BrokenApp
  def initialize(app)
    @app = app
  end

  def call(env)
    [200, nil, []]
  end
end

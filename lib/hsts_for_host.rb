# frozen_string_literal: true

require "rack"

class HstsForHost
  def initialize(app, host:, policy: "max-age=63072000; includeSubDomains; preload")
    @app = app
    @host = host
    @policy = policy
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers["strict-transport-security"] = @policy if Rack::Request.new(env).host == @host
    [status, headers, body]
  end
end

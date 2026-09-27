# frozen_string_literal: true

require "json"

# Bearer token access for bots. Deliberately not a BaseController: there is
# no session, so neither the login redirect nor CSRF checks apply.
class ApiController < Sinatra::Base
  MAX_CONTENT_SIZE = 1024 * 1024
  # Form encoded bodies are consumed by Sinatra's params parsing
  CONTENT_TYPES = %w(text/markdown text/plain).freeze

  helpers do
    def bearer_token
      request.env["HTTP_AUTHORIZATION"].to_s[/\ABearer (\S+)\z/, 1]
    end

    def authenticate!
      BotCredential.authenticate(bearer_token) || halt(401, "Unauthorized")
    end

    def page_etag(page)
      %("#{page.sha1}")
    end
  end

  post '/enroll' do
    credential, secret = BotCredential.enroll(bearer_token)
    halt 401, "Unauthorized" unless credential

    content_type :json
    { secret: secret, page: "/api/pages/#{credential.page_id}" }.to_json
  end

  get '/pages/:id' do |id|
    credential = authenticate!
    halt 404, "Not found" unless credential.page_id == id.to_i

    page = credential.page
    cache_control :private, no_store: true
    headers "ETag" => page_etag(page)
    content_type "text/markdown", charset: "utf-8"
    page.content.to_s
  end

  put '/pages/:id' do |id|
    credential = authenticate!
    halt 404, "Not found" unless credential.page_id == id.to_i

    if_match = request.env["HTTP_IF_MATCH"]
    halt 428, "If-Match required" unless if_match

    halt 415, "Content-Type must be text/markdown" unless CONTENT_TYPES.include?(request.media_type)

    content = String.new(request.body.read(MAX_CONTENT_SIZE + 1).to_s, encoding: Encoding::UTF_8)
    halt 413, "Content too large" if content.bytesize > MAX_CONTENT_SIZE
    halt 400, "Content must be UTF-8" unless content.valid_encoding?

    page = Page.db.transaction do
      locked = Page.where(id: credential.page_id).for_update.first
      next unless if_match == page_etag(locked)

      locked.revise!
      locked.content = content
      locked.comment = params[:comment]
      locked.author = credential.bot
      locked.save
    end
    halt 412, "Page changed" unless page

    headers "ETag" => page_etag(page)
    content_type :json
    { revision: page.revision, sha1: page.sha1 }.to_json
  end
end

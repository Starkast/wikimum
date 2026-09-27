# frozen_string_literal: true

require "json"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppApiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def setup
    @owner = User.create(login: "owner")
    @page = Page.create(title: "Rates ÅÄÖ", author: @owner, content: "SEK 1.0")
    @credential, @enrollment_token = BotCredential.issue(page: @page, owner: @owner, name: "rates")
  end

  def teardown
    bot = @credential.bot
    @credential.delete
    Revision.where(page_id: @page.id).delete
    @page.destroy
    bot.delete
    @owner.destroy
  end

  def write(body, path: "/api/pages/#{@page.id}")
    put path, body, "CONTENT_TYPE" => "text/markdown"
  end

  def bearer(token)
    header "Authorization", "Bearer #{token}"
  end

  def enroll
    bearer @enrollment_token
    post "/api/enroll"
    @secret = JSON.parse(last_response.body).fetch("secret")
    bearer @secret
  end

  def test_enrollment_token_works_once
    enroll
    assert_match(/\Awm_bot_#{@credential.id}_\h{64}\z/, @secret)

    bearer @enrollment_token
    post "/api/enroll"
    assert_equal 401, last_response.status
  end

  def test_expired_enrollment_token_is_rejected
    @credential.update(enrollment_expires_on: Time.now - 1)
    bearer @enrollment_token

    post "/api/enroll"

    assert_equal 401, last_response.status
  end

  def test_read_and_write_round_trip
    enroll

    get "/api/pages/#{@page.id}"
    assert_equal "SEK 1.0", last_response.body
    etag = last_response["ETag"]

    header "If-Match", etag
    write "SEK 1.1", path: "/api/pages/#{@page.id}?comment=daily"

    assert_equal 200, last_response.status
    @page.reload
    assert_equal "SEK 1.1", @page.content
    assert_equal "daily", @page.comment
    assert_equal "rates (via owner)", @page.author.to_s
    assert_equal %("#{@page.sha1}"), last_response["ETag"]
    refute_nil @credential.reload.last_used_on
  end

  def test_write_requires_if_match
    enroll

    write "blind"

    assert_equal 428, last_response.status
    assert_equal "SEK 1.0", @page.reload.content
  end

  def test_write_with_stale_etag_is_rejected
    enroll
    get "/api/pages/#{@page.id}"
    etag = last_response["ETag"]
    @page.update(content: "human edit")

    header "If-Match", etag
    write "SEK 1.1"

    assert_equal 412, last_response.status
    assert_equal "human edit", @page.reload.content
  end

  def test_write_requires_markdown_content_type
    enroll
    get "/api/pages/#{@page.id}"
    header "If-Match", last_response["ETag"]

    put "/api/pages/#{@page.id}", "SEK 1.1"

    assert_equal 415, last_response.status
  end

  def test_credential_is_scoped_to_its_page
    other = Page.create(title: "Other ÅÄÖ", author: @owner)
    enroll

    get "/api/pages/#{other.id}"

    assert_equal 404, last_response.status
  ensure
    other&.destroy
  end

  def test_revoked_credential_is_rejected
    enroll
    @credential.revoke!

    get "/api/pages/#{@page.id}"

    assert_equal 401, last_response.status
  end

  def test_enrollment_token_is_not_a_secret
    bearer @enrollment_token

    get "/api/pages/#{@page.id}"

    assert_equal 401, last_response.status
  end
end

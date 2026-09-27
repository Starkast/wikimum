# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppBotsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def setup
    @owner = User.create(login: "owner")
    @other = User.create(login: "other")
    @page = Page.create(title: "Bot Page ÅÄÖ", author: @owner)
  end

  def teardown
    bots = User.where(owner_id: [@owner.id, @other.id])
    BotCredential.where(bot_id: bots.select(:id)).delete
    Revision.where(page_id: @page.id).delete
    @page.destroy
    bots.delete
    @owner.destroy
    @other.destroy
  end

  def login(user, starkast: false)
    session = { login: user.login, user_id: user.id, starkast: }
    env "rack.session", session
    header "X-CSRF-Token", Rack::Protection::AuthenticityToken.token(session)
  end

  def create_bot(name = "rates")
    post "/#{@page.slug_for_uri}/bots", name: name
    @page.bot_credentials_dataset.order(:id).last
  end

  def test_creating_a_bot_shows_a_one_time_enrollment_token
    login(@owner)

    credential = create_bot

    assert_equal 200, last_response.status
    assert_match(/wm_enroll_#{credential.id}_\h{64}/, last_response.body)
    assert_includes last_response.headers["Cache-Control"], "no-store"
    assert_equal "rates (via owner)", credential.bot.to_s
    assert_nil credential.secret_digest

    get "/#{@page.slug_for_uri}/bots"
    refute_match(/wm_enroll_/, last_response.body)
    assert_includes last_response.body, "Väntar på registrering"
  end

  def test_owner_can_revoke
    login(@owner)
    credential = create_bot

    post "/#{@page.slug_for_uri}/bots/#{credential.id}/revoke"

    assert_equal 302, last_response.status
    refute_nil credential.reload.revoked_on
  end

  def test_others_cannot_revoke
    login(@owner)
    credential = create_bot
    login(@other)

    post "/#{@page.slug_for_uri}/bots/#{credential.id}/revoke"

    assert_equal 403, last_response.status
    assert_nil credential.reload.revoked_on
  end

  def test_bots_on_concealed_pages_require_starkast
    @page.update(visibility: Page::CONCEALED)
    login(@owner)

    post "/#{@page.slug_for_uri}/bots", name: "infra"
    assert_equal 302, last_response.status
    assert_empty @page.bot_credentials

    login(@owner, starkast: true)
    refute_nil create_bot("infra")
  end

  def test_anonymous_cannot_list_bots
    get "/#{@page.slug_for_uri}/bots"

    assert_equal 401, last_response.status
  end
end

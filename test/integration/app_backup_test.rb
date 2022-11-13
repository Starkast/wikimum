# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppBackupTest < Minitest::Test
  include Rack::Test::Methods

  OUTER_APP = Rack::Builder.parse_file("config.ru").first

  def app
    OUTER_APP
  end

  def setup
    @page_title = "Test åäö"
    @user = User.create(email: "test@test", login: "test")
    @page = Page.create(title: @page_title, author: @user)
  end

  def teardown
    @page.destroy
    @user.destroy
  end

  def test_backup
    username, password = ["user", "pass"]

    ClimateControl.modify(BACKUP_USER: username, BACKUP_PASSWORD: password) do
      basic_authorize username, password
      post "/.backup"

      follow_redirect!

      # Need to force encoding due to this line?
      # https://github.com/rack/rack/blob/2.2.4/lib/rack/mock.rb#L156
      body = last_response.body.force_encoding(Encoding::UTF_8)
      match_failed_message = <<~MSG
        did not find @page_title=#{@page_title.inspect} in the SQL dump
      MSG

      assert last_response.ok?
      assert_match(/#{@page_title}/, body, match_failed_message)
    end
  end

  def test_backup_without_auth
    post "/.backup"

    assert last_response.unauthorized?
  end

  def test_backup_with_incorrect_auth
    ClimateControl.modify(BACKUP_USER: "user", BACKUP_PASSWORD: "pass") do
      basic_authorize "foo", "bar"
      post "/.backup"

      assert last_response.unauthorized?
    end
  end

  def test_backup_with_auth_not_configured
    assert_raises(KeyError) do |raised_error|
      basic_authorize "foo", "bar"
      post "/.backup"

      assert_match(/key not found: "BACKUP_USER"/, raised_error.message)
    end
  end
end

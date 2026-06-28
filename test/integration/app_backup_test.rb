# frozen_string_literal: true

require "base64"
require "fileutils"
require "securerandom"
require "tmpdir"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppBackupTest < Minitest::Test
  include Rack::Test::Methods

  def app
    DYNAMIC_APP.call
  end

  def with_app_loaded
    app
    yield
  end

  def setup
    with_app_loaded do
      @page_title = "Test åäö"
      @user = User.create(email: "test@test", login: "test")
      @page = Page.create(title: @page_title, author: @user)
    end
  end

  def teardown
    @page.destroy
    @user.destroy
  end

  def assert_backup(maintenance_mode: false)
    username, password = ["user", "pass"]
    env_hash = {
      BACKUP_USER: username,
      BACKUP_PASSWORD: password,
      MAINTENANCE_MODE: maintenance_mode.to_s,
    }

    ClimateControl.modify(env_hash) do
      basic_authorize username, password
      post "/.backup"

      follow_redirect!

      # Need to force encoding due to this line?
      # https://github.com/rack/rack/blob/2.2.4/lib/rack/mock.rb#L156
      body = last_response.body.force_encoding(Encoding::UTF_8)
      match_failed_message = <<~MSG
        did not find @page_title=#{@page_title.inspect} in the SQL dump
      MSG

      assert_equal 200, last_response.status
      assert_match(/#{@page_title}/, body, match_failed_message)
    end
  end

  def test_backup
    assert_backup
  end

  def test_backup_in_maintenance_mode
    assert_backup(maintenance_mode: true)
  end

  # A GC pass between the backup and download requests must not delete the dump.
  def test_backup_survives_gc_before_download
    username, password = ["user", "pass"]

    ClimateControl.modify(BACKUP_USER: username, BACKUP_PASSWORD: password) do
      basic_authorize username, password
      post "/.backup"

      GC.start

      follow_redirect!

      body = last_response.body.force_encoding(Encoding::UTF_8)
      assert_equal 200, last_response.status
      assert_match(/#{@page_title}/, body)
    end
  end

  # Each backup must sweep stale dumps so they do not accumulate on disk.
  def test_backup_sweeps_stale_dumps
    backup_dir = File.join(Dir.tmpdir, "wiki_backup")
    FileUtils.mkdir_p(backup_dir)
    stale = File.join(backup_dir, "dump-#{SecureRandom.uuid}.sql")
    File.write(stale, "old dump")
    File.utime(Time.now - 7200, Time.now - 7200, stale)

    username, password = ["user", "pass"]
    ClimateControl.modify(BACKUP_USER: username, BACKUP_PASSWORD: password) do
      basic_authorize username, password
      post "/.backup"
      follow_redirect!

      assert_equal 200, last_response.status
    end

    refute File.exist?(stale), "expected stale dump to be swept"
  end

  def test_download_rejects_path_traversal
    backup_dir = File.join(Dir.tmpdir, "wiki_backup")
    FileUtils.mkdir_p(backup_dir)
    secret = File.join(Dir.tmpdir, "wiki_backup_secret_#{SecureRandom.hex}.txt")
    File.write(secret, "TOP SECRET")

    encoded = Base64.urlsafe_encode64("../#{File.basename(secret)}")

    ClimateControl.modify(BACKUP_USER: "user", BACKUP_PASSWORD: "pass") do
      basic_authorize "user", "pass"
      post "/.backup/download/#{encoded}"
    end

    refute_equal 200, last_response.status
    refute_includes last_response.body.to_s, "TOP SECRET"
  ensure
    File.delete(secret) if secret && File.exist?(secret)
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

# frozen_string_literal: true

require "base64"
require "cgi"
require "json"
require "securerandom"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppPageUploadsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def ensure_logged_in_user(user)
    env "rack.session", { login: user.login, user_id: user.id }
  end

  def setup
    @user = User.create(email: "test@test", login: "test")
    @page = Page.create(title: "Test Page", author: @user)
    ensure_logged_in_user(@user)
  end

  def teardown
    @page.uploads.each(&:destroy)
    @page.revisions.each(&:destroy)
    @page.destroy
    @user.destroy
  end

  def test_upload_file
    file_content = "Hello, World!"
    uploaded_file = Rack::Test::UploadedFile.new(
      StringIO.new(file_content),
      "text/plain",
      original_filename: "test.txt"
    )

    post "/#{CGI.escape(@page.slug)}/uploads", file: uploaded_file

    assert_equal 200, last_response.status

    response = JSON.parse(last_response.body)
    assert response["id"]
    refute_includes response["path"], "/test.txt"
    assert_includes response["markdown"], "[test.txt]"
  end

  def test_upload_image
    # 1x1 transparent PNG
    png_data = Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    )
    uploaded_file = Rack::Test::UploadedFile.new(
      StringIO.new(png_data),
      "image/png",
      original_filename: "test.png"
    )

    post "/#{CGI.escape(@page.slug)}/uploads", file: uploaded_file

    assert_equal 200, last_response.status

    response = JSON.parse(last_response.body)
    assert_includes response["markdown"], "![test.png]"
  end

  def test_get_upload
    upload = Upload.create(
      page: @page,
      author: @user,
      filename: "test.txt",
      content_type: "text/plain",
      data: Sequel.blob("Hello, World!")
    )

    get "/#{CGI.escape(@page.slug)}/uploads/#{upload.id}/test.txt"

    assert_equal 200, last_response.status
    assert last_response.content_type.start_with?("text/plain")
    assert_equal "Hello, World!", last_response.body
    assert_includes last_response.headers["cache-control"], "public"
  end

  def test_list_uploads
    Upload.create(
      page: @page,
      author: @user,
      filename: "file1.txt",
      content_type: "text/plain",
      data: Sequel.blob("content1")
    )
    Upload.create(
      page: @page,
      author: @user,
      filename: "file2.txt",
      content_type: "text/plain",
      data: Sequel.blob("content2")
    )

    get "/#{CGI.escape(@page.slug)}/uploads"

    assert_equal 200, last_response.status

    response = JSON.parse(last_response.body)
    assert_equal 2, response.length
    assert_equal "file1.txt", response[0]["filename"]
    assert_equal "file2.txt", response[1]["filename"]
  end

  def test_delete_upload
    upload = Upload.create(
      page: @page,
      author: @user,
      filename: "test.txt",
      content_type: "text/plain",
      data: Sequel.blob("Hello, World!")
    )

    delete "/#{CGI.escape(@page.slug)}/uploads/#{upload.id}"

    assert_equal 200, last_response.status
    assert_nil Upload[upload.id]
  end

  def test_upload_requires_login
    env "rack.session", {}

    post "/#{CGI.escape(@page.slug)}/uploads", file: nil

    assert_equal 302, last_response.status
  end

  def test_get_upload_wrong_page
    other_page = Page.create(title: "Other Page", author: @user)
    upload = Upload.create(
      page: other_page,
      author: @user,
      filename: "test.txt",
      content_type: "text/plain",
      data: Sequel.blob("Hello, World!")
    )

    get "/#{CGI.escape(@page.slug)}/uploads/#{upload.id}/test.txt"

    assert_equal 404, last_response.status
  ensure
    upload&.destroy
    other_page&.destroy
  end

  def test_get_upload_concealed_page_unauthorized
    concealed_page = Page.create(title: "Concealed Page", author: @user, concealed: true)
    upload = Upload.create(
      page: concealed_page,
      author: @user,
      filename: "secret.txt",
      content_type: "text/plain",
      data: Sequel.blob("Secret content")
    )

    env "rack.session", {}
    get "/#{CGI.escape(concealed_page.slug)}/uploads/#{upload.id}/secret.txt"

    assert_equal 404, last_response.status
  ensure
    upload&.destroy
    concealed_page&.destroy
  end

  def test_get_upload_concealed_page_as_starkast
    concealed_page = Page.create(title: "Concealed Page", author: @user, concealed: true)
    upload = Upload.create(
      page: concealed_page,
      author: @user,
      filename: "secret.txt",
      content_type: "text/plain",
      data: Sequel.blob("Secret content")
    )

    env "rack.session", { login: @user.login, user_id: @user.id, starkast: true }
    get "/#{CGI.escape(concealed_page.slug)}/uploads/#{upload.id}/secret.txt"

    assert_equal 200, last_response.status
    assert_equal "Secret content", last_response.body
    assert_includes last_response.headers["cache-control"], "private"
  ensure
    upload&.destroy
    concealed_page&.destroy
  end
end

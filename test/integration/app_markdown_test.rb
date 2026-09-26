# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppMarkdownTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def setup
    @user = User.create(email: "test@test", login: "test")
    @page = Page.create(title: "Geekbench 5", content: "# Resultat\n\n| CPU | Poäng |\n", author: @user)
  end

  def teardown
    Page.where(author_id: @user.id).each do |page|
      page.revisions.each(&:destroy)
      page.destroy
    end
    @user.destroy
  end

  def login_with(starkast:)
    env "rack.session", { login: @user.login, user_id: @user.id, starkast: }
  end

  def test_page_as_markdown
    get "/#{@page.slug_for_uri}.md"

    assert last_response.ok?
    assert_equal "text/markdown;charset=utf-8", last_response.content_type
    assert_includes last_response.body, "title: Geekbench 5\n"
    assert last_response.body.end_with?("---\n\n# Resultat\n\n| CPU | Poäng |\n")
  end

  def test_page_as_markdown_is_cacheable_for_anonymous
    get "/#{@page.slug_for_uri}.md"
    etag = last_response["ETag"]

    assert_includes last_response["Cache-Control"], "public"
    refute_nil etag

    header "If-None-Match", etag
    get "/#{@page.slug_for_uri}.md"

    assert_equal 304, last_response.status
  end

  def test_missing_page_as_markdown_is_a_404_even_when_logged_in
    login_with(starkast: true)

    get "/does_not_exist.md"

    assert_equal 404, last_response.status
    assert_equal "text/markdown;charset=utf-8", last_response.content_type
  end

  def test_concealed_page_as_markdown_is_a_404_for_anonymous
    @page.update(visibility: "concealed")

    get "/#{@page.slug_for_uri}.md"

    assert_equal 404, last_response.status
    refute_includes last_response.body, "Resultat"
  end

  def test_concealed_page_as_markdown_for_starkast
    @page.update(visibility: "concealed")
    login_with(starkast: true)

    get "/#{@page.slug_for_uri}.md"

    assert last_response.ok?
    assert_includes last_response.body, "# Resultat"
    assert_includes last_response["Cache-Control"], "private"
  end

  def test_unicode_slug_as_markdown
    page = Page.create(title: "Åäö sida", content: "Hej", author: @user)

    get "/#{page.slug_for_uri}.md"

    assert last_response.ok?
    assert last_response.body.end_with?("Hej")
  end
end

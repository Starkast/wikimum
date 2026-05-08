# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppSearchTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def setup
    @user = User.create(email: "test@test", login: "test")
    @apple = Page.create(title: "Apple Pie", content: "tasty fruit dessert", author: @user)
    @apple_juice = Page.create(title: "Apple Juice", content: "fresh squeezed", author: @user)
    @banana = Page.create(title: "Banana Bread", content: "ripe fruit baked", author: @user)
    @concealed = Page.create(title: "Apple Secret", content: "hidden notes", author: @user, concealed: true)
  end

  def teardown
    [@apple, @apple_juice, @banana, @concealed].each(&:destroy)
    @user.destroy
  end

  def test_search_matches_in_title
    get "/search", q: "Apple"

    assert_predicate last_response, :ok?
    assert_includes last_response.body, "Apple Pie"
    assert_includes last_response.body, "Apple Juice"
    refute_includes last_response.body, "Banana Bread"
  end

  def test_search_matches_in_content
    get "/search", q: "fruit"

    assert_predicate last_response, :ok?
    assert_includes last_response.body, "Apple Pie"
    assert_includes last_response.body, "Banana Bread"
  end

  def test_search_is_case_insensitive
    get "/search", q: "apple"

    assert_predicate last_response, :ok?
    assert_includes last_response.body, "Apple Pie"
  end

  def test_search_requires_all_terms
    get "/search", q: "apple banana"

    assert_equal 302, last_response.status
    refute_match(/apple_pie|banana_bread/i, last_response["Location"].to_s)
  end

  def test_search_excludes_concealed_pages_when_anonymous
    get "/search", q: "Apple"

    refute_includes last_response.body, "Apple Secret"
  end

  def test_search_single_match_redirects_to_page
    get "/search", q: "squeezed"

    assert_equal 302, last_response.status
    assert_match(/apple_juice/, last_response["Location"])
  end
end

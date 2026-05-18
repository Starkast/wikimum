# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../integration_test_helper'

class PageTest < Minitest::Test
  def setup
    @user = User.create(email: "page_test@test", login: "page_tester")
  end

  def teardown
    @page&.revisions&.each(&:destroy)
    @page&.destroy
    @user&.destroy
  end

  def test_search_with_tsquery_special_chars_does_not_raise
    result = nil
    assert_silent do
      result = Page.search("foo[:foo]").to_a
    end
    assert_kind_of Array, result
  end

  def test_search_with_plain_terms_still_finds_matching_pages
    @page = Page.create(title: "Hello World Bench", author: @user)

    results = Page.search("Hello").to_a

    assert_includes results.map(&:id), @page.id
  end
end

require 'minitest/autorun'
require_relative '../../lib/services/slug'

class SlugTest < MiniTest::Unit::TestCase
  def test_slug
    title = 'ape'
    assert_equal 'ape', Slug.slugify(title)
  end

  def test_slug_with_sentence
    title = 'this is a sentence'
    assert_equal 'this_is_a_sentence', Slug.slugify(title)
  end

  def test_slug_should_downcase
    title = 'Ape'
    assert_equal 'ape', Slug.slugify(title)
  end

  def test_slug_with_umlaut
    title = 'Historik för Starkast'
    assert_equal 'historik_för_starkast', Slug.slugify(title)
  end

  def test_slug_with_escaped_space
    title = 'Historik%20för%20Starkast'
    assert_equal 'historik_för_starkast', Slug.slugify(title)
  end
end

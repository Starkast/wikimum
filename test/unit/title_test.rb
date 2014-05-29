require 'minitest/autorun'
require_relative '../../lib/services/title'

class TitleTest < MiniTest::Unit::TestCase
  def test_first_char_with_english_word
    title = 'ape'
    assert_equal 'A', Title.new(title).first_char
  end

  def test_first_char_with_umlaut
    title = 'ärta'
    assert_equal '#', Title.new(title).first_char
  end

  def test_slug
    title = 'ape'
    assert_equal 'ape', Title.new(title).slug
  end

  def test_slug_with_sentence
    title = 'this is a sentence'
    assert_equal 'this_is_a_sentence', Title.new(title).slug
  end

  def test_slug_should_downcase
    title = 'Ape'
    assert_equal 'ape', Title.new(title).slug
  end
end

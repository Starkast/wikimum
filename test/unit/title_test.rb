# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/services/title'

class TitleTest < Minitest::Test
  def test_first_char_with_english_word
    title = 'ape'
    assert_equal 'A', Title.new(title).first_char
  end

  def test_first_char_with_umlaut
    title = 'ärta'
    assert_equal '#', Title.new(title).first_char
  end
end

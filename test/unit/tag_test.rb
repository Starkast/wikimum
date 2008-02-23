require File.dirname(__FILE__) + '/../test_helper'

class TagTest < Test::Unit::TestCase
  fixtures :tags

  def setup
    @tag = Tag.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Tag,  @tag
  end
end

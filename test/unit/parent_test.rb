require File.dirname(__FILE__) + '/../test_helper'

class ParentTest < Test::Unit::TestCase
  fixtures :parents

  def setup
    @parent = Parent.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Parent,  @parent
  end
end

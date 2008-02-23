require File.dirname(__FILE__) + '/../test_helper'

class ChangerTest < Test::Unit::TestCase
  fixtures :changers

  def setup
    @changer = Changer.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Changer,  @changer
  end
end

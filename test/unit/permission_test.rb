require File.dirname(__FILE__) + '/../test_helper'

class PermissionTest < Test::Unit::TestCase
  fixtures :permissions

  def setup
    @permission = Permission.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Permission,  @permission
  end
end

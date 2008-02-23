require File.dirname(__FILE__) + '/../test_helper'

class RoleTest < Test::Unit::TestCase
  fixtures :roles

  def setup
    @role = Role.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Role,  @role
  end
end

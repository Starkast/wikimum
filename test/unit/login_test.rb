require File.dirname(__FILE__) + '/../test_helper'

class LoginTest < Test::Unit::TestCase
  fixtures :logins

  def setup
    @login = Login.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Login,  @login
  end
end

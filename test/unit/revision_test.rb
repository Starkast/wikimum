require File.dirname(__FILE__) + '/../test_helper'

class RevisionTest < Test::Unit::TestCase
  fixtures :revisions

  def setup
    @revision = Revision.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Revision,  @revision
  end
end

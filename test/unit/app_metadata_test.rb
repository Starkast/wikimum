# frozen_string_literal: true

require_relative '../test_helper'
require_relative "../../lib/services/app_metadata"

class AppMetadataTest < Minitest::Test
  def test_release_version
    refute_empty AppMetadata.release_version
  end

  def test_commit
    refute_empty AppMetadata.commit
  end

  def test_short_commit
    ClimateControl.modify(HEROKU_SLUG_COMMIT: "bad0a554069af49b3de35b8e8c26765c1dba9ff02") do
      assert_equal "bad0a55", AppMetadata.short_commit
    end
  end
end

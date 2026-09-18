# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class DbPoolTest < Minitest::Test
  def test_pool_size_matches_puma_max_threads
    assert_equal App.max_threads, App.db.pool.max_size
  end
end

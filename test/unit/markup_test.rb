require 'minitest/autorun'
require_relative '../../lib/services/markup'

class MarkupTest < MiniTest::Unit::TestCase
  def test_wikify_content
    content = '[[Server]]'
    output = '[Server](/Server)'

    assert_equal output, Markup.wikify_content(content)
  end

  def test_wikified_with_markdown
    content = '[[Server]]'
    html_output = "<p><a href=\"/Server\">Server</a></p>\n"

    assert_equal html_output, Markup.to_html(content)
  end
end

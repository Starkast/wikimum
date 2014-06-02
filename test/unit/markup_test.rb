require 'minitest/autorun'
require_relative '../../lib/services/markup'

class MarkupTest < MiniTest::Unit::TestCase
  def test_wiki_link_filter
    content = '[[Server]]'
    output = '[Server](/Server)'

    doc = HTML::Pipeline.parse(content)

    assert_equal output, WikiLinkFilter.call(doc, {})
  end

  def test_wikified_with_markdown
    content = '[[Server]]'
    html_output = "<p><a href=\"/Server\">Server</a></p>"

    assert_equal html_output, Markup.to_html(content)
  end
end

require 'minitest/autorun'
require_relative '../../lib/services/markup'

class MarkupTest < Minitest::Test
  def test_wiki_link_filter
    content     = %([[Server]])
    html_output = %(<a href="/Server">Server</a>)

    doc = HTML::Pipeline.parse(content)

    assert_equal html_output, WikiLinkFilter.call(doc, {})
  end

  def test_wiki_link_filter_with_multiple_links_on_one_row
    content     = %([[Server]] [[Hardware]])
    html_output = %(<a href="/Server">Server</a> <a href="/Hardware">Hardware</a>)

    doc = HTML::Pipeline.parse(content)

    assert_equal html_output, WikiLinkFilter.call(doc, {})
  end

  def test_wiki_link_filter_with_multiple_links_on_two_rows
    content     = %([[Server]]\n[[Hardware]])
    html_output = %(<a href="/Server">Server</a>\n<a href="/Hardware">Hardware</a>)

    doc = HTML::Pipeline.parse(content)

    assert_equal html_output, WikiLinkFilter.call(doc, {})
  end

  def test_wikified_with_markdown
    content     = %([[Server]])
    html_output = %(<p><a href="/Server">Server</a></p>\n)

    assert_equal html_output, Markup.to_html(content)
  end

  def test_markdown_blockquote
    content     = %(> test)
    html_output = %(<blockquote>\n<p>test</p>\n</blockquote>\n)

    assert_equal html_output, Markup.to_html(content)
  end
end

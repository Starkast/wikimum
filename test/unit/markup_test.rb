# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/services/markup'

class MarkupTest < Minitest::Test
  def test_nil_content
    content     = nil
    html_output = ""

    assert_equal html_output, Markup.to_html(content)
  end

  def test_wiki_link_filter
    content     = %([[Server]])
    html_output = %(<p><a href="/Server">Server</a></p>\n)

    assert_equal html_output, Markup.to_html(content)
  end

  def test_wiki_link_filter_with_multiple_links_on_one_row
    content     = %([[Server]] [[Hardware]])
    html_output = %(<p><a href="/Server">Server</a> <a href="/Hardware">Hardware</a></p>\n)

    assert_equal html_output, Markup.to_html(content)
  end

  def test_wiki_link_filter_with_multiple_links_on_two_rows
    content     = %([[Server]]\n[[Hardware]])
    html_output = %(<p><a href="/Server">Server</a>\n<a href="/Hardware">Hardware</a></p>\n)

    assert_equal html_output, Markup.to_html(content)
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

  # The CommonMarker options below match what github-markup 5.0.1's
  # MARKUP_MARKDOWN handler passed through. They lock in the rendered
  # output for each so we don't silently regress when the renderer is
  # swapped or its options are changed.

  def test_github_pre_lang_option_uses_pre_lang_attribute
    content     = "```ruby\nputs \"hi\"\n```"
    html_output = %(<pre lang="ruby"><code>puts &quot;hi&quot;\n</code></pre>\n)

    assert_equal html_output, Markup.to_html(content)
  end

  def test_strikethrough_extension
    content     = "~~old~~ new"
    html_output = %(<p><del>old</del> new</p>\n)

    assert_equal html_output, Markup.to_html(content)
  end

  def test_table_extension
    content = <<~MD
      | a | b |
      |---|---|
      | 1 | 2 |
    MD
    html_output = "<table>\n<thead>\n<tr>\n<th>a</th>\n<th>b</th>\n</tr>\n</thead>\n" \
      "<tbody>\n<tr>\n<td>1</td>\n<td>2</td>\n</tr>\n</tbody>\n</table>\n"

    assert_equal html_output, Markup.to_html(content)
  end

  def test_autolink_extension_links_bare_urls
    content     = "see https://example.com here"
    html_output = %(<p>see <a href="https://example.com">https://example.com</a> here</p>\n)

    assert_equal html_output, Markup.to_html(content)
  end

  def test_tagfilter_strips_script_tags
    assert_equal "\n", Markup.to_html("<script>alert(1)</script>")
  end

  def test_tagfilter_strips_iframe_tags
    assert_equal "\n", Markup.to_html(%(<iframe src="x"></iframe>))
  end

  def test_headings_render_without_anchor_links
    content     = "## Foo Bar"
    html_output = "<h2>Foo Bar</h2>\n"

    assert_equal html_output, Markup.to_html(content)
  end

  # Commonmarker 2.x enables a few extensions by default that github-markup +
  # commonmarker 0.x did not. The tests below pin our intent: keep wiki
  # rendering stable instead of inheriting newer defaults.

  def test_tasklist_markers_render_literally
    content     = "- [ ] todo\n- [x] done"
    html_output = "<ul>\n<li>[ ] todo</li>\n<li>[x] done</li>\n</ul>\n"

    assert_equal html_output, Markup.to_html(content)
  end

  def test_shortcodes_are_not_expanded_to_emoji
    content     = "I am :smile: happy"
    html_output = "<p>I am :smile: happy</p>\n"

    assert_equal html_output, Markup.to_html(content)
  end

  def test_escaped_characters_render_without_span_wrappers
    content     = "\\!important"
    html_output = "<p>!important</p>\n"

    assert_equal html_output, Markup.to_html(content)
  end
end

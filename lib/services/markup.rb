require 'html/pipeline'
require 'github/markup'

class Markup
  def self.to_html(content)
    pipeline = HTML::Pipeline.new [
      MarkdownFilter,
      WikiLinkFilter,
    ]
    result = pipeline.call(content)
    result.fetch(:output).to_s
  end
end

class MarkdownFilter < HTML::Pipeline::TextFilter
  def call
    GitHub::Markup.render_s(GitHub::Markups::MARKUP_MARKDOWN, text)
  end
end

class WikiLinkFilter < HTML::Pipeline::Filter

  WIKI_LINK_REGEXP = /\[\[(?<link>[\d\w\sÅÄÖåäö:-]{1,35})\]\]/i

  def call
    content = doc.to_s
    content.gsub(WIKI_LINK_REGEXP) do |word|
      link = word.match(WIKI_LINK_REGEXP)[:link]
      %(<a href="/#{link}">#{link}</a>)
    end
  end
end

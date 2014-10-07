require 'html/pipeline'

class Markup
  def self.to_html(content)
    pipeline = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      WikiLinkFilter,
    ]
    result = pipeline.call(content)
    result.fetch(:output).to_s
  end
end

class WikiLinkFilter < HTML::Pipeline::Filter

  WIKI_LINK_REGEXP = /\[\[(?<link>[\d\w\sÅÄÖåäö_:-]{1,35})\]\]/i

  def call
    content = doc.to_s
    content.gsub(WIKI_LINK_REGEXP) do |word|
      link = word.match(WIKI_LINK_REGEXP)[:link]
      %(<a href="/#{link}">#{link}</a>)
    end
  end
end

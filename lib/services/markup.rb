# frozen_string_literal: true

require 'html-pipeline'
require 'github/markup'

class Markup
  def self.to_html(content)
    text_filters = [
      MarkdownFilter,
      WikiLinkFilter,
    ]
    pipeline = HTMLPipeline.new(text_filters:)
    pipeline.to_html(content.to_s, context: {}, result: {})
  end
end

class MarkdownFilter < HTMLPipeline::TextFilter
  def call
    GitHub::Markup.render_s(GitHub::Markups::MARKUP_MARKDOWN, text)
  end
end

class WikiLinkFilter < HTMLPipeline::TextFilter
  WIKI_LINK_REGEXP = /\[\[(?<link>[\d\w\sÅÄÖåäö:-]{1,35})\]\]/i.freeze

  def call
    content = text
    content.gsub(WIKI_LINK_REGEXP) do |word|
      link = word.match(WIKI_LINK_REGEXP)[:link]
      %(<a href="/#{link}">#{link}</a>)
    end
  end
end

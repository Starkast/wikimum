# frozen_string_literal: true

require 'html-pipeline'
require 'commonmarker'

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
  # Match github-markup 5.0.1's MARKUP_MARKDOWN handler so output is identical
  # to the prior GitHub::Markup.render_s(MARKUP_MARKDOWN, ...) call.
  COMMONMARKER_OPTS = [:GITHUB_PRE_LANG].freeze
  COMMONMARKER_EXTS = %i[tagfilter autolink table strikethrough].freeze

  def call
    CommonMarker.render_html(text, COMMONMARKER_OPTS, COMMONMARKER_EXTS)
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

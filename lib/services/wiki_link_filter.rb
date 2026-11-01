# frozen_string_literal: true

require 'html-pipeline'

class WikiLinkFilter < HTMLPipeline::TextFilter
  WIKI_LINK_REGEXP = /\[\[(?<link>[\d\w\sÅÄÖåäö.:-]{1,35})\]\]/i.freeze

  def call(text, context: {}, result: {})
    text.gsub(WIKI_LINK_REGEXP) do |word|
      link = word.match(WIKI_LINK_REGEXP)[:link]
      %(<a href="/#{link}">#{link}</a>)
    end
  end
end

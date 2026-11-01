# frozen_string_literal: true

require 'html-pipeline'

class Markup
  def self.to_html(content)
    # Commonmarker 2.x rejects non-UTF-8 input; nil.to_s is US-ASCII.
    return "" if content.nil? || content.empty?

    text_filters = [
      MarkdownFilter.new,
      WikiLinkFilter.new,
    ]
    pipeline = HTMLPipeline.new(text_filters:)
    pipeline.to_html(content, context: {}, result: {})
  end
end

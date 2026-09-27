# frozen_string_literal: true

require 'html-pipeline'

class Markup
  PIPELINE = HTMLPipeline.new(text_filters: [MarkdownFilter.new, WikiLinkFilter.new])

  def self.to_html(content)
    # Commonmarker 2.x rejects non-UTF-8 input; nil.to_s is US-ASCII.
    return "" if content.nil? || content.empty?

    PIPELINE.to_html(content, context: {}, result: {})
  end
end

require 'html/pipeline'

class Markup
  def self.to_html(content)
    pipeline = HTML::Pipeline.new [
      WikiLinkFilter,
      HTML::Pipeline::MarkdownFilter,
    ]
    result = pipeline.call(content)
    result.fetch(:output).to_s
  end
end

class WikiLinkFilter < HTML::Pipeline::Filter
  def call
    content = doc.to_s
    content.gsub(/\[\[([\d\w\sÅÄÖåäö_:-]{1,35})\]\]/i) do
      "[#{$1}](/#{$1})"
    end
  end
end

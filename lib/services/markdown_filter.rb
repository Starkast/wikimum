# frozen_string_literal: true

require 'html-pipeline'
require 'commonmarker'

class MarkdownFilter < HTMLPipeline::TextFilter
  # Keep rendering close to what github-markup 5.0.1 + commonmarker 0.x used to
  # produce. Defaults that match what we want are not listed; defaults that
  # don't are overridden here. See Commonmarker::Config::OPTIONS for the full
  # set: https://github.com/gjtorikian/commonmarker/blob/v2.9.0/lib/commonmarker/config.rb
  COMMONMARKER_OPTIONS = {
    render: {
      hardbreaks: false,         # default true; single \n stays a soft break, not <br />
      escaped_char_spans: false, # default true; \! renders as ! not <span>!</span>
    },
    extension: {
      header_ids: nil, # default ""; nil suppresses <a> anchors injected into headings
      tasklist:   false, # default true; render `- [ ]` literally instead of stripping
      shortcodes: false, # default true; render `:smile:` literally, no emoji expansion
    },
  }.freeze
  COMMONMARKER_PLUGINS = { syntax_highlighter: nil }.freeze

  def call(text, context: {}, result: {})
    Commonmarker.to_html(text, options: COMMONMARKER_OPTIONS, plugins: COMMONMARKER_PLUGINS)
  end
end

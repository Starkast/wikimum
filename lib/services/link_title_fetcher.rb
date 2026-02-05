# frozen_string_literal: true

require 'httpx'
require 'cgi'

class LinkTitleFetcher
  MAX_BYTES = 32_768
  TIMEOUT = 3
  MAX_REDIRECTS = 3

  URL_PATTERN = %r{https?://[^\s)\]<>"]+}
  MARKDOWN_LINK_PATTERN = /\[([^\]]+)\]\(([^)]+)\)/
  TITLE_PATTERN = %r{<title[^>]*>([^<]+)</title>}i

  def initialize(http: nil, log: nil)
    @http = http
    @log = log
  end

  def http
    @http || HTTPX.plugin(:stream)
                  .plugin(:follow_redirects)
                  .with(timeout: { operation_timeout: TIMEOUT }, follow_redirects: { max_redirects: MAX_REDIRECTS })
  end

  def log
    @log || App.log
  end

  def extract_bare_urls(content)
    linked_urls = content.scan(MARKDOWN_LINK_PATTERN).map { |_, url| url }
    all_urls = content.scan(URL_PATTERN).uniq
    all_urls - linked_urls
  end

  def fetch_title(url)
    response = http.get(url, stream: true)
    return { url: url, error: "HTTP #{response.status}" } unless response.status == 200

    buffer = +""
    response.each do |chunk|
      buffer << chunk
      if (match = buffer.match(TITLE_PATTERN))
        title = decode_entities(match[1].strip)
        log.info class: self.class.name, method: __method__, url: url, bytes: buffer.bytesize, title: title
        return { url: url, title: title }
      end
      break if buffer.bytesize >= MAX_BYTES
    end
    log.warn class: self.class.name, method: __method__, url: url, bytes: buffer.bytesize, error: "No title found"
    { url: url, error: "No title found" }
  rescue StandardError => e
    log.error class: self.class.name, method: __method__, url: url, error: e.class, message: e.message.inspect
    { url: url, error: e.message }
  end

  private

  def decode_entities(text)
    CGI.unescapeHTML(text)
  end
end

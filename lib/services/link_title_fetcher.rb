# frozen_string_literal: true

require 'httpx'
require 'cgi'

class LinkTitleFetcher
  MAX_BYTES = 32_768
  TIMEOUT = 3
  MAX_REDIRECTS = 3

  URL_PATTERN = %r{https?://[^\s)\]<>"]+}
  MARKDOWN_LINK_PATTERN = /\[([^\]]+)\]\(([^)]+)\)/

  def initialize(http: nil)
    @http = http
  end

  def http
    @http || HTTPX.plugin(:stream)
                  .plugin(:follow_redirects)
                  .with(timeout: { operation_timeout: TIMEOUT }, follow_redirects: { max_redirects: MAX_REDIRECTS })
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
      if (match = buffer.match(%r{<title[^>]*>([^<]+)</title>}i))
        return { url: url, title: decode_entities(match[1].strip) }
      end
      break if buffer.bytesize >= MAX_BYTES
    end
    { url: url, error: "No title found" }
  rescue StandardError => e
    warn "at=error class=LinkTitleFetcher method=fetch_title url=#{url} error=#{e.class} message=#{e.message.inspect}"
    { url: url, error: e.message }
  end

  private

  def decode_entities(text)
    CGI.unescapeHTML(text)
  end
end

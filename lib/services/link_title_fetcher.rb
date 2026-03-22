# frozen_string_literal: true

require 'httpx'
require 'cgi'

class LinkTitleFetcher
  MAX_BYTES = 512 * 1024
  TIMEOUT = 3
  MAX_REDIRECTS = 3

  TITLE_PATTERN = %r{<title[^>]*>([^<]+)</title>}i

  def initialize(http: nil, log: nil)
    @http = http
    @log = log
  end

  def http
    @http || HTTPX.plugin(:stream)
                  .with(timeout: { operation_timeout: TIMEOUT })
  end

  def log
    @log || App.log
  end

  def fetch_title(url)
    current_url = url
    redirects = 0

    loop do
      response = http.get(current_url, stream: true)

      if redirect?(response.status)
        redirects += 1
        return { url: url, error: "Too many redirects" } if redirects > MAX_REDIRECTS

        location = response.headers["location"]
        return { url: url, error: "Missing redirect location" } unless location

        current_url = resolve_redirect(current_url, location)
        unless UrlValidator.safe?(current_url)
          log.warn class: self.class.name, method: __method__, url: url, redirect: current_url, error: "Redirect blocked"
          return { url: url, error: "Redirect to blocked URL" }
        end
        next
      end

      return extract_title(url, current_url, response)
    end
  rescue StandardError => e
    log.error class: self.class.name, method: __method__, url: url, error: e.class, message: e.message
    { url: url, error: e.message }
  end

  private

  def redirect?(status)
    [301, 302, 303, 307, 308].include?(status)
  end

  def resolve_redirect(base_url, location)
    URI.join(base_url, location).to_s
  end

  def extract_title(original_url, current_url, response)
    buffer = +""
    response.each do |chunk|
      buffer << chunk
      if (match = buffer.match(TITLE_PATTERN))
        title = decode_entities(match[1].strip)
        log.info class: self.class.name, method: __method__, url: original_url, bytes: buffer.bytesize, title: title
        return { url: original_url, title: title }
      end
      break if buffer.bytesize >= MAX_BYTES
    end
    log.warn class: self.class.name, method: __method__, url: original_url, bytes: buffer.bytesize, error: "No title found"
    { url: original_url, error: "No title found" }
  end

  def decode_entities(text)
    CGI.unescapeHTML(text)
  end
end

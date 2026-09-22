# frozen_string_literal: true

require 'httpx'
require 'cgi/escape'
require 'resolv'

class LinkTitleFetcher
  MAX_BYTES = 512 * 1024
  TIMEOUT = 3
  MAX_REDIRECTS = 3

  TITLE_PATTERN = %r{<title[^>]*>([^<]+)</title>}i

  def initialize(http: nil, log: nil, resolver: Resolv)
    @http = http
    @log = log
    @resolver = resolver
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

    (MAX_REDIRECTS + 1).times do |hop|
      addresses = UrlValidator.new(current_url, resolver: @resolver).addresses
      return blocked(url, current_url, hop) if addresses.empty?

      response = http.with(addresses: addresses).get(current_url, stream: true)
      return extract_title(url, current_url, response) unless redirect?(status(response))

      location = response.headers["location"]
      return { url: url, error: "Missing redirect location" } unless location

      current_url = resolve_redirect(current_url, location)
    end

    { url: url, error: "Too many redirects" }
  rescue StandardError => e
    log.error class: self.class.name, method: __method__, url: url, error: e.class, message: e.message
    { url: url, error: e.message }
  end

  private

  def blocked(url, current_url, hop)
    error = hop.zero? ? "Blocked URL" : "Redirect to blocked URL"
    log.warn class: self.class.name, method: :fetch_title, url: url, blocked: current_url, error: error
    { url: url, error: error }
  end

  def redirect?(status)
    [301, 302, 303, 307, 308].include?(status)
  end

  # HTTPX's stream response raises StopIteration on the first access when the body is empty.
  def status(response)
    response.status
  rescue StopIteration
    response.status
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

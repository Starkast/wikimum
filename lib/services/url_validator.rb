# frozen_string_literal: true

require "uri"
require "resolv"
require "ipaddr"

class UrlValidator
  BLOCKED_RANGES = [
    IPAddr.new("0.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("100.64.0.0/10"),
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("224.0.0.0/4"),
    IPAddr.new("240.0.0.0/4"),
    IPAddr.new("::/128"),
    IPAddr.new("::1/128"),
    IPAddr.new("64:ff9b::/96"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10"),
    IPAddr.new("ff00::/8")
  ].freeze

  BLOCKED_HOSTS = %w[localhost].freeze

  def self.safe?(url)
    new(url).safe?
  end

  def initialize(url, resolver: Resolv)
    @url = url
    @resolver = resolver
  end

  def safe?
    !addresses.empty?
  end

  # Public IPs the URL host resolves to, or [] when the URL must not be fetched.
  def addresses
    @addresses ||= resolve_addresses
  end

  private

  def resolve_addresses
    uri = URI.parse(@url)
    return [] unless %w[http https].include?(uri.scheme)

    host = uri.hostname
    return [] if host.nil? || host.empty?
    return [] if BLOCKED_HOSTS.include?(host.downcase)

    ips = ip_addresses(host)
    return [] if ips.empty? || ips.any? { |ip| blocked?(ip) }

    ips.map(&:to_s)
  rescue URI::InvalidURIError, ArgumentError
    []
  end

  def ip_addresses(host)
    [IPAddr.new(host)]
  rescue IPAddr::InvalidAddressError
    lookup(host).map { |address| IPAddr.new(address) }
  end

  def lookup(host)
    @resolver.getaddresses(host)
  rescue Resolv::ResolvError
    []
  end

  def blocked?(ip)
    ip = ip.native if ip.ipv4_mapped?
    BLOCKED_RANGES.any? { |range| range.include?(ip) }
  end
end

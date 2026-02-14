# frozen_string_literal: true

require "uri"
require "resolv"
require "ipaddr"

class UrlValidator
  PRIVATE_RANGES = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("0.0.0.0/8"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10")
  ].freeze

  BLOCKED_HOSTS = %w[localhost].freeze

  def self.safe?(url)
    new(url).safe?
  end

  def initialize(url)
    @url = url
  end

  def safe?
    uri = URI.parse(@url)
    return false unless %w[http https].include?(uri.scheme)
    return false unless uri.host
    return false if BLOCKED_HOSTS.include?(uri.host.downcase)
    return false if private_ip?(uri.host)

    # Resolve DNS and check resolved IPs
    ips = resolve_ips(uri.host)
    return false if ips.empty?
    return false if ips.any? { |ip| private_ip?(ip) }

    true
  rescue URI::InvalidURIError, ArgumentError
    false
  end

  private

  def private_ip?(host)
    return false unless host

    ip = IPAddr.new(host)
    PRIVATE_RANGES.any? { |range| range.include?(ip) }
  rescue IPAddr::InvalidAddressError
    false
  end

  def resolve_ips(host)
    Resolv.getaddresses(host)
  rescue Resolv::ResolvError
    []
  end
end

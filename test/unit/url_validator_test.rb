# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/services/url_validator"

class UrlValidatorTest < Minitest::Test
  def test_allows_https_url
    assert UrlValidator.safe?("https://example.com")
  end

  def test_allows_http_url
    assert UrlValidator.safe?("http://example.com")
  end

  def test_blocks_non_http_schemes
    refute UrlValidator.safe?("ftp://example.com")
    refute UrlValidator.safe?("file:///etc/passwd")
    refute UrlValidator.safe?("javascript:alert(1)")
  end

  def test_blocks_localhost
    refute UrlValidator.safe?("http://localhost")
    refute UrlValidator.safe?("http://localhost:8080")
  end

  def test_blocks_loopback_ip
    refute UrlValidator.safe?("http://127.0.0.1")
    refute UrlValidator.safe?("http://127.0.0.1:8080")
    refute UrlValidator.safe?("http://127.1.2.3")
  end

  def test_blocks_private_class_a
    refute UrlValidator.safe?("http://10.0.0.1")
    refute UrlValidator.safe?("http://10.255.255.255")
  end

  def test_blocks_private_class_b
    refute UrlValidator.safe?("http://172.16.0.1")
    refute UrlValidator.safe?("http://172.31.255.255")
  end

  def test_blocks_private_class_c
    refute UrlValidator.safe?("http://192.168.0.1")
    refute UrlValidator.safe?("http://192.168.255.255")
  end

  def test_blocks_link_local
    refute UrlValidator.safe?("http://169.254.1.1")
  end

  def test_blocks_ipv6_loopback
    refute UrlValidator.safe?("http://[::1]")
  end

  def test_blocks_invalid_urls
    refute UrlValidator.safe?("not a url")
    refute UrlValidator.safe?("")
  end

  def test_blocks_url_without_host
    refute UrlValidator.safe?("http:///path")
    refute UrlValidator.safe?("https:///")
  end

  def test_blocks_cloud_metadata_ips
    refute UrlValidator.safe?("http://169.254.169.254")
  end

  def test_blocks_carrier_grade_nat
    refute UrlValidator.safe?("http://100.64.0.1")
    refute UrlValidator.safe?("http://100.64.3.2")
    refute UrlValidator.safe?("http://100.127.255.255")
  end

  def test_blocks_ipv4_mapped_ipv6
    refute UrlValidator.safe?("http://[::ffff:127.0.0.1]")
    refute UrlValidator.safe?("http://[::ffff:7f00:1]")
    refute UrlValidator.safe?("http://[::ffff:10.0.0.1]")
    refute UrlValidator.safe?("http://[::ffff:100.64.3.2]")
  end

  def test_blocks_ipv6_unspecified_and_nat64
    refute UrlValidator.safe?("http://[::]")
    refute UrlValidator.safe?("http://[64:ff9b::7f00:1]")
  end

  def test_blocks_multicast_and_broadcast
    refute UrlValidator.safe?("http://224.0.0.1")
    refute UrlValidator.safe?("http://255.255.255.255")
    refute UrlValidator.safe?("http://[ff02::1]")
  end

  def test_blocks_hostname_resolving_to_private_ip
    resolver = FakeResolver.new("internal.example" => %w[93.184.216.34 10.0.0.5])

    refute UrlValidator.new("http://internal.example", resolver: resolver).safe?
  end

  def test_blocks_hostname_resolving_to_mapped_loopback
    resolver = FakeResolver.new("mapped.example" => %w[::ffff:127.0.0.1])

    refute UrlValidator.new("http://mapped.example", resolver: resolver).safe?
  end

  def test_addresses_returns_validated_ips
    resolver = FakeResolver.new("public.example" => %w[93.184.216.34 2606:2800:220:1:248:1893:25c8:1946])

    validator = UrlValidator.new("https://public.example/page", resolver: resolver)

    assert validator.safe?
    assert_equal %w[93.184.216.34 2606:2800:220:1:248:1893:25c8:1946], validator.addresses
  end

  def test_addresses_is_empty_for_blocked_url
    resolver = FakeResolver.new("internal.example" => %w[10.0.0.5])

    assert_empty UrlValidator.new("http://internal.example", resolver: resolver).addresses
  end

  def test_addresses_for_ip_literal_skips_dns
    resolver = FakeResolver.new({})

    assert_equal %w[93.184.216.34], UrlValidator.new("http://93.184.216.34", resolver: resolver).addresses
  end
end

class FakeResolver
  def initialize(answers)
    @answers = answers
  end

  def getaddresses(host)
    @answers.fetch(host, [])
  end
end

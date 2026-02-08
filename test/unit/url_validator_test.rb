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

  def test_blocks_cloud_metadata_ips
    refute UrlValidator.safe?("http://169.254.169.254")
  end
end

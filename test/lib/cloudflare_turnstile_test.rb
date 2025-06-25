require "test_helper"

class CloudflareTurnstileTest < ActiveSupport::TestCase
  test "should return false for blank payload" do
    result = CloudflareTurnstile.validate("", "127.0.0.1")
    assert_equal false, result
  end

  test "should return false for nil payload" do
    result = CloudflareTurnstile.validate(nil, "127.0.0.1")
    assert_equal false, result
  end

  test "should have secret key configured" do
    turnstile = CloudflareTurnstile.new("test", "127.0.0.1")
    # Access private method to test secret key configuration
    secret_key = turnstile.send(:secret_key)
    assert_not_nil secret_key
    # Should use test key in test environment
    assert_equal "1x0000000000000000000000000000000AA", secret_key
  end

  test "should initialize with payload and remote_ip" do
    payload = "test_token"
    remote_ip = "192.168.1.1"
    turnstile = CloudflareTurnstile.new(payload, remote_ip)

    assert_equal payload, turnstile.instance_variable_get(:@payload)
    assert_equal remote_ip, turnstile.instance_variable_get(:@remote_ip)
  end

  test "should use test secret key in test environment" do
    # Verify the secret key logic works correctly in test environment
    turnstile = CloudflareTurnstile.new("test", "127.0.0.1")
    secret_key = turnstile.send(:secret_key)

    # Test key should be used in test environment regardless of credentials
    assert_equal "1x0000000000000000000000000000000AA", secret_key
  end
end

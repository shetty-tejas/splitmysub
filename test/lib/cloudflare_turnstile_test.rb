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
    # Should use test key by default
    assert_equal "1x0000000000000000000000000000000AA", secret_key
  end

  test "should validate with mocked HTTP response" do
    # Mock successful HTTP response
    http_response = mock()
    http_response.expects(:body).returns('{"success": true}')
    Net::HTTP.expects(:post_form).returns(http_response)

    result = CloudflareTurnstile.validate("valid_token", "127.0.0.1")
    assert_equal true, result
  end

  test "should handle failed validation with mocked HTTP response" do
    # Mock failed HTTP response
    http_response = mock()
    http_response.expects(:body).returns('{"success": false}')
    Net::HTTP.expects(:post_form).returns(http_response)

    result = CloudflareTurnstile.validate("invalid_token", "127.0.0.1")
    assert_equal false, result
  end

  test "should handle network errors gracefully" do
    # Mock network error
    Net::HTTP.expects(:post_form).raises(Errno::ETIMEDOUT)

    result = CloudflareTurnstile.validate("test_token", "127.0.0.1")
    assert_equal false, result
  end
end

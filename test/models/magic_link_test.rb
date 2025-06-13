require "test_helper"

class MagicLinkTest < ActiveSupport::TestCase
  test "should belong to user" do
    magic_link = magic_links(:login_link)
    assert_respond_to magic_link, :user
    assert_instance_of User, magic_link.user
  end

  test "should have required attributes" do
    magic_link = magic_links(:login_link)
    assert_not_nil magic_link.token
    assert_not_nil magic_link.expires_at
    assert_not_nil magic_link.used
  end

  test "should be valid with valid attributes" do
    magic_link = MagicLink.new(
      user: users(:test_user),
      token: "test123",
      expires_at: 1.hour.from_now,
      used: false
    )
    assert magic_link.valid?
  end
end

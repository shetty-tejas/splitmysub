ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper for admin authentication in tests
    def admin_authenticate
      # Set the environment variable for HTTP Basic auth
      ENV["ADMIN_PASSWORD"] = "test_admin_password"

      # Encode credentials for HTTP Basic authentication
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials("superadmin", "test_admin_password")

      # Return the authorization header
      { "Authorization" => credentials }
    end

    def sign_in_as(user)
      magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
      get verify_magic_link_url(token: magic_link.token)
    end
  end
end

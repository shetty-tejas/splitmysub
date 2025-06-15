require "test_helper"

class ApplicationControllerTest < ActiveSupport::TestCase
  test "error handlers are defined" do
    controller = ApplicationController.new

    # Check that error handling methods exist
    assert controller.respond_to?(:handle_standard_error, true)
    assert controller.respond_to?(:handle_not_found, true)
    assert controller.respond_to?(:handle_parameter_missing, true)
    assert controller.respond_to?(:handle_unpermitted_parameters, true)
    assert controller.respond_to?(:handle_rate_limit_exceeded, true)
  end

  test "rescue_from handlers are configured" do
    # Check that ApplicationController has rescue_from handlers configured
    rescue_handlers = ApplicationController.rescue_handlers

    # Should have handlers for the exceptions we care about
    handler_classes = rescue_handlers.map(&:first)

    assert_includes handler_classes, "StandardError"
    assert_includes handler_classes, "ActiveRecord::RecordNotFound"
    assert_includes handler_classes, "ActionController::ParameterMissing"
    assert_includes handler_classes, "ActionController::UnpermittedParameters"
    assert_includes handler_classes, "Rack::Attack::Throttle"
  end

  test "ApplicationController includes required concerns" do
    # Check that required concerns are included
    assert ApplicationController.included_modules.include?(Authentication)
    assert ApplicationController.included_modules.include?(Authorization)
  end

  test "CSRF protection is enabled" do
    # Check that CSRF protection is enabled
    assert ApplicationController.included_modules.include?(ActionController::RequestForgeryProtection)
    assert_not_nil ApplicationController.forgery_protection_strategy
  end
end

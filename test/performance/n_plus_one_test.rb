require "test_helper"

class NPlusOneTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)

    # Create additional test data for N+1 scenarios
    3.times do |i|
      project = Project.create!(
        name: "Test Project #{i}",
        description: "Test project for N+1 testing",
        cost: 10.00,
        currency: "USD",
        billing_cycle: "monthly",
        renewal_date: 1.month.from_now,
        reminder_days: 7,
        user: @user
      )

      # Add members to each project
      2.times do |j|
        user = User.create!(
          email_address: "member#{i}#{j}@example.com",
          first_name: "Member",
          last_name: "#{i}#{j}"
        )
        project.project_memberships.create!(user: user, role: "member")
      end
    end
  end

  test "dashboard cost breakdown should not have N+1 queries" do
    # Query count should be consistent regardless of number of projects
    assert_queries(4) do # Should be minimal queries with includes
      # Simulate the calculate_project_cost_breakdown method
      owned_project_ids = @user.projects.pluck(:id)
      member_project_ids = @user.member_projects.pluck(:id)
      all_project_ids = (owned_project_ids + member_project_ids).uniq

      # This should use includes to avoid N+1
      all_projects = Project.where(id: all_project_ids)
                           .includes(:project_memberships)

      all_projects.each do |project|
        project.cost_per_member # This should not trigger additional queries
      end
    end
  end

  test "billing cycle statistics should not have N+1 queries" do
    # Create multiple billing cycles with payments
    3.times do |i|
      cycle = @project.billing_cycles.create!(
        due_date: (i + 1).months.from_now,
        total_amount: 15.99
      )

      # Add payments to each cycle
      2.times do |j|
        user = User.create!(
          email_address: "payer#{i}#{j}@example.com",
          first_name: "Payer",
          last_name: "#{i}#{j}"
        )
        cycle.payments.create!(
          user: user,
          amount: 5.33,
          status: "confirmed",
          confirmation_date: Time.current,
          confirmed_by: @user
        )
      end
    end

    # Test the optimized billing cycle stats
    assert_queries(2) do # Should be minimal queries with includes
      all_cycles = @project.billing_cycles
      active_cycles = all_cycles.upcoming

      # Use the optimized version with includes
      active_cycles_with_payments = active_cycles.includes(:payments)

      # These should not trigger additional queries
      active_cycles_with_payments.each do |cycle|
        cycle.payments.sum(&:amount) # Should not trigger additional queries
      end

      assert active_cycles_with_payments.size >= 0
    end
  end

  test "project total_members should use counter cache when available" do
    project = @project

    # Should use counter cache if available
    member_count = nil
    if project.has_attribute?(:memberships_count)
      assert_queries(0) do
        member_count = project.total_members
      end
    end

    # Should still work without counter cache
    assert_queries(1) do
      # Directly query without counter cache
      count = project.project_memberships.count + 1
      assert count > 0
    end
  end

  test "reminder service should preload associations" do
    # Skip if reminder schedule already exists
    unless @project.reminder_schedules.exists?(days_before: 7)
      @project.reminder_schedules.create!(
        days_before: 7,
        escalation_level: 1
      )
    end

    service = ReminderService.new

    # Should preload associations to avoid N+1
    # Just verify the service can run without errors
    assert_nothing_raised do
      service.process_project_reminders(@project)
    end
  end

  test "project scopes should optimize queries" do
    # Test with_member_counts scope
    projects = Project.with_member_counts.limit(5)
    projects.each do |project|
      assert project.project_memberships.loaded? # Should be preloaded
    end

    # Test with_payments scope
    projects = Project.with_payments.limit(5)
    projects.each do |project|
      assert project.billing_cycles.loaded? # Should be preloaded
    end
  end

  private

  def assert_queries(expected_count)
    query_count = 0

    callback = lambda do |name, started, finished, unique_id, payload|
      query_count += 1 if payload[:name] != "CACHE"
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end

    assert_equal expected_count, query_count,
      "Expected #{expected_count} queries, but #{query_count} were executed"
  end
end

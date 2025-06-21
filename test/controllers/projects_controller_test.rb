require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
        setup do
    @user = users(:test_user)
    @other_user = users(:other_user)
    @project = projects(:netflix)
    @other_project = projects(:adobe)

    # Sign in the user using magic link
    sign_in_as(@user)
  end

  private

  def sign_in_as(user)
    magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
    get verify_magic_link_url(token: magic_link.token)
  end



  test "should get new" do
    get new_project_url
    assert_response :success
    assert_includes response.body, "projects/new"
  end

  test "should create project" do
    assert_difference("Project.count") do
      post projects_url, params: {
        project: {
          name: "Test Project",
          description: "Test Description",
          cost: 15.99,
          billing_cycle: "monthly",
          renewal_date: 1.month.from_now.to_date,
          reminder_days: 7,
          payment_instructions: "Pay via Venmo",
          subscription_url: "https://example.com"
        }
      }
    end

    project = Project.last
    assert_equal @user, project.user
    assert_redirected_to project_url(project)
  end

  test "should not create project with invalid data" do
    assert_no_difference("Project.count") do
      post projects_url, params: {
        project: {
          name: "",
          cost: -5,
          billing_cycle: "invalid"
        }
      }
    end

    assert_redirected_to new_project_url
  end

  test "should show project when owner" do
    get project_url(@project)
    assert_response :success
    assert_includes response.body, "projects/show"
  end

  test "should show project when member" do
    # Use the existing membership from fixtures
    sign_in_as(@other_user)
    get project_url(@project) # netflix project where other_user is a member
    assert_response :success
    assert_includes response.body, "projects/show"
  end

  test "should not show project when not owner or member" do
    # Create a new project owned by other_user that test_user has no access to
    no_access_project = Project.create!(
      name: "No Access Project",
      cost: 10.0,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      reminder_days: 7,
      user: @other_user
    )
    get project_url(no_access_project)
    assert_redirected_to dashboard_url
    assert_equal "You don't have access to this project.", flash[:alert]
  end

  test "should get edit when owner" do
    get edit_project_url(@project)
    assert_response :success
    assert_includes response.body, "projects/edit"
  end

  test "should not get edit when not owner" do
    no_access_project = Project.create!(
      name: "No Access Project",
      cost: 10.0,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      reminder_days: 7,
      user: @other_user
    )
    get edit_project_url(no_access_project)
    assert_redirected_to dashboard_url
    assert_equal "You can only edit projects you own.", flash[:alert]
  end

  test "should update project when owner" do
    patch project_url(@project), params: {
      project: {
        name: "Updated Project Name",
        cost: 25.99
      }
    }

    @project.reload
    assert_equal "Updated Project Name", @project.name
    assert_equal 25.99, @project.cost
    assert_redirected_to project_url(@project)
  end

  test "should not update project when not owner" do
    no_access_project = Project.create!(
      name: "No Access Project",
      cost: 10.0,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      reminder_days: 7,
      user: @other_user
    )
    original_name = no_access_project.name
    patch project_url(no_access_project), params: {
      project: { name: "Hacked Name" }
    }

    no_access_project.reload
    assert_equal original_name, no_access_project.name
    assert_redirected_to dashboard_url
    assert_equal "You can only edit projects you own.", flash[:alert]
  end

  test "should not update project with invalid data" do
    original_name = @project.name
    patch project_url(@project), params: {
      project: {
        name: "",
        cost: -10
      }
    }

    @project.reload
    assert_equal original_name, @project.name
    assert_redirected_to edit_project_url(@project)
  end

  test "should destroy project when owner" do
    assert_difference("Project.count", -1) do
      delete project_url(@project)
    end

    assert_redirected_to dashboard_url
    assert_equal "Project deleted successfully!", flash[:notice]
  end

  test "should not destroy project when not owner" do
    no_access_project = Project.create!(
      name: "No Access Project",
      cost: 10.0,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      reminder_days: 7,
      user: @other_user
    )
    assert_no_difference("Project.count") do
      delete project_url(no_access_project)
    end

    assert_redirected_to dashboard_url
    assert_equal "You can only edit projects you own.", flash[:alert]
  end

  test "should handle project not found" do
    get project_url(id: 99999)
    assert_redirected_to dashboard_url
    assert_equal "Project not found.", flash[:alert]
  end



  test "project json should include correct data" do
    get project_url(@project)
    assert_response :success

    # The response should include project data in the correct format
    # This tests the project_json and detailed_project_json methods
    assert_includes response.body, @project.name
    assert_includes response.body, @project.cost.to_s
  end

  test "should validate authorization for all protected actions" do
    no_access_project = Project.create!(
      name: "No Access Project",
      cost: 10.0,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      reminder_days: 7,
      user: @other_user
    )
    protected_actions = [
      [ :get, :edit ],
      [ :patch, :update ],
      [ :delete, :destroy ]
    ]

    protected_actions.each do |method, action|
      send(method, url_for(controller: :projects, action: action, id: no_access_project))
      assert_redirected_to dashboard_url
      assert_equal "You can only edit projects you own.", flash[:alert]
    end
  end
end

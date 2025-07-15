class AddMembershipsCountToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :memberships_count, :integer, default: 0, null: false

    # Reset counter cache for existing projects
    reversible do |dir|
      dir.up do
        Project.find_each do |project|
          Project.reset_counters(project.id, :project_memberships)
        end
      end
    end
  end
end

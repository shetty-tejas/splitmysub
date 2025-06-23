class AddSlugToProjects < ActiveRecord::Migration[8.0]
  def up
    add_column :projects, :slug, :string, null: true
    add_index :projects, :slug, unique: true

    # Generate unique 10-character numeric slugs for existing projects
    Project.find_each do |project|
      loop do
        slug = generate_numeric_slug
        unless Project.exists?(slug: slug)
          project.update_column(:slug, slug)
          break
        end
      end
    end

    # Make slug not null after populating existing records
    change_column_null :projects, :slug, false
  end

  def down
    remove_index :projects, :slug
    remove_column :projects, :slug
  end

  private

  def generate_numeric_slug
    # Generate a 10-character numeric string
    10.times.map { rand(10) }.join
  end
end

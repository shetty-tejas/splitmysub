class AddDescriptionAndSubscriptionUrlToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :description, :text
    add_column :projects, :subscription_url, :string
  end
end

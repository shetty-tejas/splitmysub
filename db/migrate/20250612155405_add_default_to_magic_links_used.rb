class AddDefaultToMagicLinksUsed < ActiveRecord::Migration[8.0]
  def change
    change_column_default :magic_links, :used, false

    # Update existing records that have nil values
    reversible do |dir|
      dir.up do
        execute "UPDATE magic_links SET used = false WHERE used IS NULL"
      end
    end
  end
end

class AddWeekendsOnlyToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :weekends_only, :boolean, default: false, null: false
  end
end

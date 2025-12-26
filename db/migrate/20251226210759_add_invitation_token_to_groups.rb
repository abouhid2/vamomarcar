class AddInvitationTokenToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :invitation_token, :string
    add_column :groups, :invitation_enabled, :boolean, default: false, null: false

    add_index :groups, :invitation_token, unique: true
  end
end

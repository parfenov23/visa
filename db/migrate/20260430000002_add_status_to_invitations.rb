class AddStatusToInvitations < ActiveRecord::Migration[7.0]
  def change
    add_column :invitations, :status, :string, default: 'in_progress', null: false
    add_index :invitations, :status
  end
end
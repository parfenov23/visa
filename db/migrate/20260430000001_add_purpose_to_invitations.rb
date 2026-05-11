class AddPurposeToInvitations < ActiveRecord::Migration[7.0]
  def change
    add_column :invitations, :purpose, :string, default: 'tourism', null: false
  end
end
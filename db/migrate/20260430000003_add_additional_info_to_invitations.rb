class AddAdditionalInfoToInvitations < ActiveRecord::Migration[7.0]
  def change
    add_column :invitations, :additional_info, :text
  end
end
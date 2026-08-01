class AddVerifyTokenToInvitations < ActiveRecord::Migration[7.0]
  def up
    add_column :invitations, :verify_token, :string
    add_index  :invitations, :verify_token, unique: true

    # Бэкфилл токенов для уже существующих приглашений.
    Invitation.reset_column_information
    Invitation.where(verify_token: nil).find_each do |inv|
      inv.update_columns(verify_token: SecureRandom.alphanumeric(10))
    end
  end

  def down
    remove_index  :invitations, :verify_token
    remove_column :invitations, :verify_token
  end
end

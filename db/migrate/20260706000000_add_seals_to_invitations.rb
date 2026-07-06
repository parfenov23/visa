class AddSealsToInvitations < ActiveRecord::Migration[7.0]
  def up
    add_column :invitations, :seal_left, :integer
    add_column :invitations, :seal_right, :integer

    # Backfill existing rows so their seals stay stable on re-download.
    Invitation.reset_column_information
    Invitation.where(seal_left: nil).or(Invitation.where(seal_right: nil)).find_each do |inv|
      left, right = (1..Invitation::SEALS_COUNT).to_a.sample(2)
      inv.update_columns(seal_left: left, seal_right: right)
    end
  end

  def down
    remove_column :invitations, :seal_left
    remove_column :invitations, :seal_right
  end
end

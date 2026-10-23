class AddInvitationNumberToInvitations < ActiveRecord::Migration[7.0]
  def up
    add_column :invitations, :invitation_number, :string

    # Бэкфилл. Раньше номер вычислялся из created_at (ddmmyyHHMM), поэтому заявки,
    # созданные в одну минуту, получали одинаковый номер. Самая ранняя заявка
    # сохраняет свой номер; более поздние дубли получают ближайший свободный (+1).
    # Сначала резервируем все «естественные» номера, чтобы сдвинутый дубль не занял
    # номер, который уже выдан другой заявке.
    Invitation.reset_column_information
    rows = Invitation.order(:created_at, :id).pluck(:id, :created_at)
                     .map { |id, created_at| [id, created_at.strftime("%d%m%y%H%M")] }

    taken = Set.new
    duplicates = []
    rows.each do |id, number|
      duplicates << [id, number] unless taken.add?(number)
    end

    assigned = rows.to_h
    duplicates.each do |id, original|
      number = original
      number = Invitation.next_number(number) while taken.include?(number)
      taken << number
      assigned[id] = number
      say "Invitation ##{id}: #{original} -> #{number}"
    end

    assigned.each { |id, number| Invitation.where(id: id).update_all(invitation_number: number) }

    add_index :invitations, :invitation_number, unique: true
  end

  def down
    remove_index  :invitations, :invitation_number
    remove_column :invitations, :invitation_number
  end
end

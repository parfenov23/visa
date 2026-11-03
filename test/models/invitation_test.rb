require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "normalize_date_string handles user-typed formats" do
    assert_equal "20.08.2026", Invitation.normalize_date_string("20/08/2026")
    assert_equal "04.12.1987", Invitation.normalize_date_string("04 12 1987")
    assert_equal "20.08.2026", Invitation.normalize_date_string("20-08-2026")
    assert_equal "20.08.2026", Invitation.normalize_date_string("2026-08-20")
    assert_equal "20.08.2026", Invitation.normalize_date_string("20.08.2026")
    assert_equal "05.08.2026", Invitation.normalize_date_string("5.8.2026")
  end

  test "normalize_date_string rejects unparseable values" do
    assert_nil Invitation.normalize_date_string("")
    assert_nil Invitation.normalize_date_string(nil)
    assert_nil Invitation.normalize_date_string("august 20, 2026")
    assert_nil Invitation.normalize_date_string("20/08/26")
    assert_nil Invitation.normalize_date_string("32.13.2026")
  end

  test "date fields are normalized on save" do
    invitation = Invitation.new(
      currency: "usd", tariff: "default", package: "single",
      birthDate: "04 12 1987",
      arival_date: "20/08/2026",
      departure_date: "not a date"
    )
    invitation.save!

    assert_equal "04.12.1987", invitation.birthDate
    assert_equal "20.08.2026", invitation.arival_date
    assert_equal "not a date", invitation.departure_date
  end

  test "invitations created in the same minute get distinct sequential numbers" do
    travel_to Time.zone.local(2026, 10, 23, 12, 50, 47) do
      attrs = { currency: "usd", tariff: "default", package: "single" }
      first  = Invitation.create!(attrs)
      second = Invitation.create!(attrs)

      assert_equal "2310261250", first.invitation_number
      assert_equal "2310261251", second.invitation_number
      assert_equal "2310261251", second.current_id
    end
  end

  test "next_number keeps leading zero" do
    assert_equal "0510261547", Invitation.next_number("0510261546")
  end

  test "new invitation defaults: not agency, seal printed, normal seal position" do
    invitation = Invitation.create!(currency: "usd", tariff: "default", package: "single")

    assert_not invitation.agency?
    assert invitation.print_seal?
    assert_not invitation.seal_high?
  end

  test "duplicate and cancelled invitations are excluded from active scope" do
    attrs = { currency: "usd", tariff: "default", package: "single" }
    done      = Invitation.create!(attrs.merge(status: "done"))
    duplicate = Invitation.create!(attrs.merge(status: "duplicate"))
    cancelled = Invitation.create!(attrs.merge(status: "cancelled", cancel_reason: "passport typo"))

    assert_includes Invitation.active, done
    assert_not_includes Invitation.active, duplicate
    assert_not_includes Invitation.active, cancelled
    assert duplicate.void?
    assert cancelled.void?
    assert_not done.void?
  end

  test "unknown status is rejected" do
    invitation = Invitation.new(currency: "usd", tariff: "default", package: "single", status: "deleted")

    assert_not invitation.valid?
    assert invitation.errors[:status].any?
  end

  test "hotel picker option includes city" do
    hotel = Hotel.new(name: "Cosmos", city: " Moscow ")

    assert_equal "Moscow", hotel.as_picker_option[:city]
  end
end

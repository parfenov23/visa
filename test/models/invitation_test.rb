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
end
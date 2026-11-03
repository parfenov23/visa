require "test_helper"

class ArrivalReminderTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @today = Date.new(2026, 11, 10)
    @smtp_to = ENV["SMTP_TO_EMAIL"]
    ENV["SMTP_TO_EMAIL"] = "admin@example.com"
  end

  teardown do
    ENV["SMTP_TO_EMAIL"] = @smtp_to
  end

  def create_invitation(arrival, attrs = {})
    inv = Invitation.create!({ currency: "usd", tariff: "default", package: "single", status: "done",
                               email: "client@example.com", arival_date: arrival }.merge(attrs))
    inv.update_columns(created_at: 10.days.ago)
    inv
  end

  test "reminds 3 days before arrival, once, only done non-agency invitations" do
    due       = create_invitation("13.11.2026")
    late      = create_invitation("11.11.2026")              # пропущенный день — всё равно напомним
    too_early = create_invitation("20.11.2026")
    past      = create_invitation("09.11.2026")
    agency    = create_invitation("13.11.2026", agency: true)
    cancelled = create_invitation("13.11.2026", status: "cancelled")
    broken    = create_invitation("13.11.2026")
    broken.update_columns(arival_date: "next week")

    ids = ArrivalReminder.new(today: @today, logger: Logger.new(nil)).due.map(&:id)
    assert_equal [due.id, late.id].sort, ids.sort
    [too_early, past, agency, cancelled, broken].each { |inv| assert_not_includes ids, inv.id }

    assert_emails(2) { ArrivalReminder.deliver_due(today: @today, logger: Logger.new(nil)) }
    assert_not_nil due.reload.reminder_sent_at
    assert_emails(0) { ArrivalReminder.deliver_due(today: @today, logger: Logger.new(nil)) }
  end
end

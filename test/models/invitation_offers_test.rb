require "test_helper"

class InvitationOffersTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @smtp_to = ENV["SMTP_TO_EMAIL"]
    ENV["SMTP_TO_EMAIL"] = "admin@example.com"
  end

  teardown do
    ENV["SMTP_TO_EMAIL"] = @smtp_to
  end

  def create_invitation(attrs = {})
    Invitation.create!({ currency: "usd", tariff: "custom_20", package: "single",
                         email: "client@example.com", citizenship: "IN" }.merge(attrs))
  end

  test "offers from admin checkboxes are normalized" do
    inv = create_invitation(offers: ["", "insurance", "vip", "unknown", "vip"])

    assert_equal %w[insurance vip], inv.offers
  end

  test "done_at is stamped on the first switch to done" do
    inv = create_invitation
    assert_nil inv.done_at

    travel_to Time.zone.local(2026, 11, 5, 12, 0) do
      inv.update!(status: "done")
    end
    first = inv.done_at
    assert_equal Time.zone.local(2026, 11, 5, 12, 0), first

    inv.update!(status: "correction")
    inv.update!(status: "done")
    assert_equal first, inv.reload.done_at
  end

  test "offers are due 5 minutes after done, not for agencies or without checkboxes" do
    due     = create_invitation(offers: %w[insurance], status: "done")
    agency  = create_invitation(offers: %w[insurance], status: "done", agency: true)
    nothing = create_invitation(status: "done")
    [due, agency, nothing].each { |i| i.update_columns(done_at: 6.minutes.ago) }
    fresh = create_invitation(offers: %w[vip], status: "done")

    assert_equal [due.id], Invitation.offers_due.pluck(:id)
    assert_not_includes Invitation.offers_due, fresh
  end

  test "deliver_offers! sends only blocks that were not sent yet" do
    inv = create_invitation(offers: %w[insurance], status: "done")

    assert_emails(1) { assert_equal %w[insurance], inv.deliver_offers! }
    assert_equal %w[insurance], inv.reload.offers_sent
    assert_emails(0) { assert_equal [], inv.deliver_offers! }

    inv.update!(offers: %w[insurance vip])
    assert_emails(1) { assert_equal %w[vip], inv.deliver_offers! }
    assert_equal %w[insurance vip], inv.reload.offers_sent
  end

  test "OffersDelivery sends due emails and can be switched off" do
    inv = create_invitation(offers: %w[insurance], status: "done")
    inv.update_columns(done_at: 10.minutes.ago)

    ENV["UPSELL_EMAILS_ENABLED"] = "off"
    assert_equal 0, OffersDelivery.deliver_due
    ENV.delete("UPSELL_EMAILS_ENABLED")

    assert_emails(1) { assert_equal 1, OffersDelivery.deliver_due }
    assert_not_nil inv.reload.offers_sent_at
  ensure
    ENV.delete("UPSELL_EMAILS_ENABLED")
  end
end

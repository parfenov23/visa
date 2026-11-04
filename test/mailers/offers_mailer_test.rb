require "test_helper"

class OffersMailerTest < ActionMailer::TestCase
  def invitation(citizenship)
    Invitation.create!(currency: "usd", tariff: "default", package: "single",
                       email: "client@example.com", citizenship: citizenship)
  end

  test "letter contains only selected blocks with the citizenship rate" do
    inv = invitation("IN")
    mail = OffersMailer.offers(inv, %w[insurance train])
    body = mail.body.encoded

    assert_equal ["client@example.com"], mail.to
    assert_equal "Your invitation is ready — useful services for your trip to Russia", mail.subject
    assert_includes body, "USD 1.35 per day"
    assert_includes body, "Train Tickets Across Russia"
    assert_includes body, "ref=#{inv.verify_token}"
    assert_not_includes body, "VIP Meet-and-Greet"
  end

  test "insurance only: rate 2 USD for other countries and insurance subject" do
    mail = OffersMailer.offers(invitation("CN"), %w[insurance])

    assert_equal "Important: medical insurance for your trip to Russia", mail.subject
    assert_includes mail.body.encoded, "USD 2 per day"
  end

  test "vip only uses the full customer text" do
    mail = OffersMailer.offers(invitation("IN"), %w[vip])

    assert_includes mail.body.encoded, "We are delighted that you have chosen our company"
  end
end

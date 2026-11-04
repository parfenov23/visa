require "test_helper"

class InvitationsReportTest < ActiveSupport::TestCase
  setup do
    Invitation.delete_all
    Country.unscoped.where(code: %w[IN NP CN]).delete_all
    Country.create!(code: "IN", title: "India")
    Country.create!(code: "NP", title: "Nepal")
    Country.create!(code: "CN", title: "China")
  end

  def invite(citizenship, at, status: "done")
    travel_to(at) do
      Invitation.create!(currency: "usd", tariff: "custom_20", package: "single",
                         citizenship: citizenship, status: status)
    end
  end

  test "daily report covers from the 1st of the month to yesterday" do
    report = InvitationsReport.daily(Date.new(2026, 11, 13))

    assert_equal Date.new(2026, 11, 1), report.from
    assert_equal Date.new(2026, 11, 12), report.to
    assert_equal Date.new(2026, 10, 1), report.prev_from
    assert_equal Date.new(2026, 10, 12), report.prev_to
  end

  test "on the 1st the daily report covers the whole previous month" do
    report = InvitationsReport.daily(Date.new(2026, 3, 1))

    assert_equal Date.new(2026, 2, 1), report.from
    assert_equal Date.new(2026, 2, 28), report.to
    assert_equal Date.new(2026, 1, 1), report.prev_from
    assert_equal Date.new(2026, 1, 31), report.prev_to
  end

  test "counts by citizenship, compares with previous period, skips void invitations" do
    invite("IN", Time.zone.local(2026, 11, 2, 10))
    invite("IN", Time.zone.local(2026, 11, 5, 10))
    invite("in", Time.zone.local(2026, 11, 12, 23, 30))
    invite("NP", Time.zone.local(2026, 11, 12, 10))
    invite("IN", Time.zone.local(2026, 11, 6, 10), status: "duplicate")
    invite("IN", Time.zone.local(2026, 11, 13, 0, 5)) # уже после периода

    invite("IN", Time.zone.local(2026, 10, 3, 10))
    invite("CN", Time.zone.local(2026, 10, 4, 10))
    invite("CN", Time.zone.local(2026, 10, 20, 10)) # после 12-го — вне периода сравнения

    report = InvitationsReport.new(from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 12))

    assert_equal 4, report.total
    assert_equal 2, report.prev_total
    assert_equal [["India", 3, 1], ["Nepal", 1, 0], ["China", 0, 1]],
                 report.rows.map { |r| [r.title, r.count, r.prev_count] }
    assert_equal ["Nepal"], report.added.map(&:title)
    assert_equal ["China"], report.gone.map(&:title)
    assert_equal ["Nepal"], report.new_on_last_day.map(&:title)
    assert_equal({ "usd" => 60.0 }, report.revenue)
  end

  test "summary email is rendered" do
    invite("IN", Time.zone.local(2026, 11, 2, 10))
    report = InvitationsReport.new(from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 12))

    mail = ReportMailer.daily_summary(report)

    assert_includes mail.subject, "01.11.2026"
    assert_includes mail.body.encoded, "India"
  end
end

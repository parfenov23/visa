# frozen_string_literal: true

# Сводка по оформленным приглашениям за период: количество по гражданству
# (топ стран), итоги и сравнение с тем же периодом прошлого месяца —
# какие страны добавились, какие ушли.
#
# Аннулированные заявки (Duplicate / Cancelled) не учитываются.
#
#   report = InvitationsReport.daily            # с 1-го числа по вчера
#   report = InvitationsReport.new(from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 12))
#   report.rows      # => [Row(code: "IN", title: "India", count: 40, prev_count: 31), ...]
#   report.added     # страны, которых не было в прошлом периоде
#   report.gone      # страны, которые были в прошлом периоде, а сейчас 0
class InvitationsReport
  UNKNOWN_CODE = "—"

  Row = Struct.new(:code, :title, :count, :prev_count, keyword_init: true) do
    def delta
      count - prev_count
    end

    def added?
      prev_count.zero? && count.positive?
    end

    def gone?
      count.zero? && prev_count.positive?
    end
  end

  attr_reader :from, :to, :prev_from, :prev_to

  # Ежедневная сводка нарастающим итогом: с 1-го числа месяца по вчерашний день.
  # 1-го числа — итоги всего прошлого месяца.
  def self.daily(today = Time.zone.today)
    to = today - 1
    new(from: to.beginning_of_month, to: to)
  end

  # Сравнение — с теми же числами прошлого месяца (1–12 ноября против 1–12 октября).
  # Если период заканчивается последним днём месяца, прошлый период — тоже до конца месяца
  # (1–28 февраля сравнивается с 1–31 января).
  def initialize(from:, to:)
    @from = from.to_date
    @to   = to.to_date
    raise ArgumentError, "from (#{@from}) must not be after to (#{@to})" if @from > @to

    @prev_from = @from.prev_month
    @prev_to   = @to == @to.end_of_month ? @to.prev_month.end_of_month : @to.prev_month
  end

  def rows
    @rows ||= begin
      codes = (current_counts.keys | prev_counts.keys)
      codes.map do |code|
        Row.new(code: code, title: country_title(code),
                count: current_counts.fetch(code, 0), prev_count: prev_counts.fetch(code, 0))
      end.sort_by { |r| [-r.count, -r.prev_count, r.title.to_s] }
    end
  end

  # Страны текущего периода (топ по количеству).
  def top
    rows.select { |r| r.count.positive? }
  end

  def added
    rows.select(&:added?)
  end

  def gone
    rows.select(&:gone?).sort_by { |r| -r.prev_count }
  end

  # Страны, впервые появившиеся в периоде в его последний день («новые за вчера»).
  def new_on_last_day
    return [] if from == to

    before = counts_for(from, to - 1)
    counts_for(to, to).keys.reject { |code| before.key?(code) }.map do |code|
      rows.find { |r| r.code == code }
    end.compact
  end

  def total
    current_counts.values.sum
  end

  def prev_total
    prev_counts.values.sum
  end

  # Сумма заказов по валютам: { "usd" => 1234.0, "eur" => 99.9 }.
  def revenue
    @revenue ||= scope_for(from, to).group(:currency).sum(:price)
                                    .transform_keys { |c| c.to_s.downcase.presence || "?" }
                                    .reject { |_, sum| sum.to_f.zero? }
  end

  def period_label
    "#{from.strftime('%d.%m.%Y')} — #{to.strftime('%d.%m.%Y')}"
  end

  def prev_period_label
    "#{prev_from.strftime('%d.%m.%Y')} — #{prev_to.strftime('%d.%m.%Y')}"
  end

  def deliver
    ReportMailer.daily_summary(self).deliver_now
  end

  private

  def current_counts
    @current_counts ||= counts_for(from, to)
  end

  def prev_counts
    @prev_counts ||= counts_for(prev_from, prev_to)
  end

  def counts_for(day_from, day_to)
    scope_for(day_from, day_to)
      .group(Arel.sql("UPPER(COALESCE(NULLIF(TRIM(citizenship), ''), '#{UNKNOWN_CODE}'))"))
      .count
  end

  def scope_for(day_from, day_to)
    Invitation.active.where(created_at: day_from.in_time_zone.beginning_of_day..day_to.in_time_zone.end_of_day)
  end

  def country_title(code)
    return "Не указано" if code == UNKNOWN_CODE

    @titles ||= Country.unscoped.where("UPPER(code) IN (?)", current_counts.keys | prev_counts.keys)
                       .each_with_object({}) { |c, h| h[c.code.upcase] = c.title }
    @titles[code] || code
  end
end

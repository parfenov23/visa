namespace :reports do
  desc "Отправить сводку по приглашениям с 1-го числа по вчера (как ежедневное письмо)"
  task daily: :environment do
    report = InvitationsReport.daily
    report.deliver
    puts "Сводка за #{report.period_label} отправлена: #{report.total} заявок"
  end

  desc "Показать сводку в консоли: rails reports:show FROM=2026-11-01 TO=2026-11-12"
  task show: :environment do
    default = InvitationsReport.daily(Time.zone.today + 1)
    from = ENV["FROM"].present? ? Date.parse(ENV["FROM"]) : default.from
    to   = ENV["TO"].present? ? Date.parse(ENV["TO"]) : default.to
    report = InvitationsReport.new(from: from, to: to)

    puts "Период #{report.period_label} (сравнение с #{report.prev_period_label}), всего #{report.total} (было #{report.prev_total})"
    report.rows.each do |r|
      puts format("%-30s %5d %5d %+5d", r.title, r.count, r.prev_count, r.delta)
    end
    puts "Добавились: #{report.added.map(&:title).join(', ')}" if report.added.any?
    puts "Ушли: #{report.gone.map(&:title).join(', ')}" if report.gone.any?
  end
end

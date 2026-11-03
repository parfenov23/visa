# Сводка по приглашениям: топ гражданств за период и сравнение с тем же
# периодом прошлого месяца. Та же сводка каждый день приходит на почту.
ActiveAdmin.register_page "Reports" do
  menu priority: 2, label: "Сводка по заявкам"

  helper do
    def report_date_param(key, default)
      Date.parse(params[key].to_s)
    rescue ArgumentError
      default
    end

    def current_report
      today   = Time.zone.today
      default = InvitationsReport.daily(today + 1) # с 1-го числа по сегодня
      from = report_date_param(:from, default.from)
      to   = report_date_param(:to, default.to)
      from, to = to, from if from > to
      InvitationsReport.new(from: from, to: to)
    end
  end

  page_action :send_email, method: :post do
    report = InvitationsReport.daily
    report.deliver
    redirect_to admin_reports_path, notice: "Сводка за #{report.period_label} отправлена на почту."
  rescue StandardError => e
    redirect_to admin_reports_path, alert: "Не удалось отправить сводку: #{e.message}"
  end

  action_item :send_email do
    link_to "Отправить вчерашнюю сводку на почту", admin_reports_send_email_path, method: :post,
            data: { confirm: "Отправить сводку с 1-го числа по вчера на почту?" }
  end

  content title: "Сводка по заявкам" do
    render partial: "admin/reports/index", locals: { report: current_report }
  end
end

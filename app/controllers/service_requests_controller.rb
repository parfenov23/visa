# Страницы доп. услуг: страховка, ЖД билеты, VIP-встреча в аэропорту.
# Все три формы отправляются в #create; тип услуги — в параметре kind.
#
# Ссылка из письма может нести ?ref=<verify_token приглашения>: тогда форма
# предзаполняется ФИО, гражданством и датами поездки, а заявка привязывается
# к приглашению. Паспорт и email не подставляются — токен напечатан в QR.
class ServiceRequestsController < ApplicationController
  PAGES = {
    'insurance' => 'insurance',
    'train'     => 'train',
    'vip'       => 'vip'
  }.freeze

  before_action -> { response.set_header("X-Robots-Tag", "noindex") }, only: :create

  def insurance
    show_page('insurance')
  end

  def train
    show_page('train')
  end

  def vip
    show_page('vip')
  end

  def create
    kind = params[:kind].to_s
    return head(:not_found) unless PAGES.key?(kind)

    @service_request = ServiceRequest.new(service_request_params.merge(kind: kind))
    @service_request.invitation = Invitation.find_by(verify_token: params[:ref]) if params[:ref].present?
    if @service_request.invitation.nil? && @service_request.invitation_ref.present?
      @service_request.invitation = Invitation.find_by(invitation_number: @service_request.invitation_ref.to_s.strip)
    end

    is_dev = Rails.env.development? || Rails.env.test?
    cf_ok  = is_dev || verify_turnstile(model: @service_request).success?

    if cf_ok && @service_request.save
      @service_request.notify!
      redirect_to page_path(kind), notice: success_message(@service_request)
    else
      @ref = params[:ref]
      render PAGES[kind], status: :unprocessable_entity
    end
  end

  private

  def show_page(kind)
    @ref = params[:ref].presence
    @service_request = ServiceRequest.new(kind: kind)
    prefill_from_invitation(@service_request, Invitation.find_by(verify_token: @ref)) if @ref
    render PAGES[kind]
  end

  def prefill_from_invitation(service_request, invitation)
    return unless invitation

    service_request.full_name   = invitation.full_name
    service_request.citizenship = invitation.citizenship
    arrival   = parse_date(invitation.arival_date)
    departure = parse_date(invitation.departure_date)
    service_request.date_from = arrival if arrival && arrival >= Time.zone.today
    service_request.date_to   = departure if service_request.insurance? && departure && arrival && departure >= arrival
    service_request.invitation_ref = invitation.current_id if service_request.vip?
  end

  def parse_date(value)
    Date.strptime(value.to_s, "%d.%m.%Y")
  rescue ArgumentError
    nil
  end

  def page_path(kind)
    { 'insurance' => insurance_path, 'train' => train_tickets_path, 'vip' => airport_transfer_path }[kind]
  end

  def success_message(service_request)
    case service_request.kind
    when 'insurance'
      "Thank you! We have received your insurance request (#{service_request.price_label}). " \
        "We will contact you by email with payment details and your policy."
    when 'train'
      "Thank you! We have received your train ticket request. " \
        "We will send you the available options and the exact price by email."
    else
      "Thank you! We have received your VIP meeting request. Our manager will contact you by email shortly."
    end
  end

  def service_request_params
    params.fetch(:service_request, {}).permit(
      :full_name, :email, :phone, :citizenship, :passport_number, :date_from, :date_to, :comments,
      :from_city, :to_city, :departure_time, :seat_class, :passengers,
      :arrival_time, :flight_number, :hotel_address, :invitation_ref,
      :passport_copy, :visa_copy
    )
  end
end

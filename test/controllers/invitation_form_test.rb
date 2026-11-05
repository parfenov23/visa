require "test_helper"

# Контракт формы заявки на главной с InvitationsController#create:
# name-атрибуты полей, hidden tariff/currency, action/method.
class InvitationFormTest < ActionDispatch::IntegrationTest
  # В test-окружении Turnstile не отключён (в отличие от development) —
  # подменяем проверку только в этом процессе тестов.
  module TurnstilePasses
    def verify_turnstile(*)
      Struct.new(:success?).new(true)
    end
  end
  InvitationsController.prepend(TurnstilePasses)

  FIELD_NAMES = %w[
    package surname name middlename sex citizenship birthDate
    arival_date departure_date passport visa_obtain_place cities hotels
    email promocode comments currency tariff
  ].freeze

  test "home page renders the application form with the expected field names" do
    get root_path
    assert_response :success

    assert_select "form#invitationForm[action=?][method=post]", invitations_path do
      FIELD_NAMES.each do |field|
        assert_select "[name=?]", field, { count: 1 }, "field #{field} is missing"
      end
      assert_select "input[type=hidden][name=tariff]"
      assert_select "input[type=hidden][name=currency]"
      assert_select "select#invitation_type_id option[data-price]"
      assert_select "button[type=submit]", text: /GET INVITATION AND INVOICE/
      FIELD_NAMES.each do |field|
        next if %w[currency tariff].include?(field)
        id = css_select("form#invitationForm [name=#{field}]").first["id"]
        assert_select "label[for=?]", id, { minimum: 1 }, "label for #{field} is missing"
      end
    end
  end

  test "/in keeps the custom_20 tariff in the form" do
    get "/in"
    assert_response :success
    assert_select "form#invitationForm input[name=tariff][value=custom_20]"
  end

  test "posting the form params creates an invitation" do
    year = Date.current.year + 1
    params = {
      currency: "usd", tariff: "default", package: "single_90",
      arival_date: "10.06.#{year}", departure_date: "20.06.#{year}",
      surname: "TESTOV", name: "IVAN", middlename: "", sex: "1", citizenship: "IND",
      birthDate: "05.04.1990", passport: "Z1234567", visa_obtain_place: "", cities: "",
      hotels: "", email: "test@example.com", promocode: "", comments: "", submit: ""
    }

    assert_difference -> { Invitation.count }, 1 do
      post invitations_path, params: params
    end
    assert_redirected_to root_path(tariff: "default")
    assert_equal "submission_success", flash[:popup]

    inv = Invitation.last
    assert_equal "TESTOV", inv.surname
    assert_equal "IND", inv.citizenship
    assert_equal "Z1234567", inv.passport
    assert_equal "test@example.com", inv.email
  end

  test "package options carry India prices for the citizenship switch" do
    get root_path
    assert_select "select#countrySelect[data-india-codes*=IND]"
    assert_select "select#invitation_type_id option[value=single][data-india-price=?]", "$ 15"
    assert_select "#invIndiaNote[hidden]"
  end

  test "India page explains how to fill surname and middle name" do
    get "/in"
    assert_select "#surname-hint", text: /dash/
    assert_select "#middlename-hint", text: /leave this field empty/

    get root_path
    assert_select "#surname-hint", count: 0
    assert_select "#middlename-hint", count: 0
  end
end

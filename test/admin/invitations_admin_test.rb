require "test_helper"

# Создание заявки вручную из админки: страница /admin/invitations/new
# падала на nil.to_sym (у новой заявки нет валюты и тарифа).
class InvitationsAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = AdminUser.find_or_create_by!(email: "admin-test@example.com") do |u|
      u.password = u.password_confirmation = "password123"
    end
    sign_in @admin
  end

  test "new invitation page renders with currency and tariff selects" do
    get new_admin_invitation_path
    assert_response :success
    assert_select "select[name='invitation[currency]']"
    assert_select "select[name='invitation[tariff]']"
    assert_select "select[name='invitation[package]'] option[value=single]"
  end

  test "invitation created in admin gets the tariff price unless a price is entered" do
    assert_difference -> { Invitation.count }, 1 do
      post admin_invitations_path, params: { invitation: { currency: "usd", tariff: "default", package: "double",
                                                           surname: "TEST", status: "in_progress", purpose: "tourism" } }
    end
    assert_equal 17.0, Invitation.last.price

    post admin_invitations_path, params: { invitation: { currency: "eur", tariff: "default", package: "single",
                                                         price: "5", surname: "TEST2", status: "in_progress", purpose: "tourism" } }
    assert_equal 5.0, Invitation.last.price
  end
end

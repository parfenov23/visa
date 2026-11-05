require "test_helper"

# Индийские цены (тариф custom_20) не должны сбрасываться при переходе по сайту:
# ни с /in (тариф в URL), ни на домене russvisa.in (тариф по домену).
class IndiaTariffNavigationTest < ActionDispatch::IntegrationTest
  setup do
    Country.create!(code: "IND", title: "India")
    Country.create!(code: "NPL", title: "Nepal")
    Country.create!(code: "DEU", title: "Germany")
  end

  test "links on /in keep the tariff" do
    get "/in"
    assert_select 'a[href="/insurance?tariff=custom_20"]'
    assert_select 'a[href="/train-tickets?tariff=custom_20"]'
    assert_select 'a[href="/?tariff=custom_20#pricing"]'
  end

  test "insurance page with india tariff shows 1.35, preselects India and keeps links" do
    get "/insurance", params: { tariff: "custom_20" }
    assert_response :success
    assert_select ".svc-badge", text: "USD 1.35 / day"
    assert_select '#countrySelect option[selected][value="IND"]'
    assert_select 'input[type="hidden"][name="tariff"][value="custom_20"]'
    assert_select 'a[href="/?tariff=custom_20#pricing"]'
  end

  test "insurance page without tariff shows the default price" do
    get "/insurance"
    assert_select ".svc-badge", text: "USD 2 / day"
    assert_select '#countrySelect option[selected]', count: 0
  end

  test "russvisa.in domain uses india prices on every page without ?tariff in links" do
    host! "russvisa.in"

    get "/"
    assert_select 'input[name="tariff"][value="custom_20"]'
    assert_select 'a[href="/insurance"]'

    get "/insurance"
    assert_select ".svc-badge", text: "USD 1.35 / day"
    assert_select 'a[href="/#pricing"]'
    assert_select 'a[href*="tariff="]', count: 0
  end

  test "india and nepal citizenship codes from the database get the 1.35 rate" do
    assert_equal 1.35, ServiceRequest.insurance_rate("IND")
    assert_equal 1.35, ServiceRequest.insurance_rate("NPL")
    assert_equal 2.0,  ServiceRequest.insurance_rate("DEU")
  end
end

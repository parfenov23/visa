require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "main page shows insurance card at 2 USD per day" do
    get root_path
    assert_response :success
    assert_includes response.body, "Medical Insurance for Russia"
    assert_includes response.body, "$ 2 / day"
  end

  test "indian page shows insurance card at 1.35 USD per day" do
    get "/in"
    assert_response :success
    assert_includes response.body, "$ 1.35 / day"
  end

  test "visitor from India sees custom_20 prices on the main page" do
    with_geo_file("127.0.0.0,127.255.255.255,IN\n") do
      get root_path
      assert_response :success
      assert_select 'input[name="tariff"][value="custom_20"]'
      assert_includes response.body, "$ 1.35 / day"

      get root_path(currency: "eur")
      assert_select 'input[name="tariff"][value="default"]'
    end
  end

  test "india geo prices can be switched off" do
    with_geo_file("127.0.0.0,127.255.255.255,IN\n") do
      ENV["INDIA_GEO_PRICES"] = "off"
      get root_path
      assert_select 'input[name="tariff"][value="default"]'
    ensure
      ENV.delete("INDIA_GEO_PRICES")
    end
  end

  private

  def with_geo_file(content)
    file = Rails.root.join("tmp/test_geo_#{SecureRandom.hex(4)}.csv")
    File.write(file, content)
    previous = ENV["GEO_COUNTRY_FILE"]
    ENV["GEO_COUNTRY_FILE"] = file.to_s
    yield
  ensure
    ENV["GEO_COUNTRY_FILE"] = previous
    File.delete(file) if file && File.exist?(file)
  end
end

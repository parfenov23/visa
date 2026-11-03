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
end

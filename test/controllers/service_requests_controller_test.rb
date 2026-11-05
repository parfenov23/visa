require "test_helper"

class ServiceRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @smtp_to = ENV["SMTP_TO_EMAIL"]
    ENV["SMTP_TO_EMAIL"] = "admin@example.com"
  end

  teardown do
    ENV["SMTP_TO_EMAIL"] = @smtp_to
  end

  test "service pages render" do
    get insurance_path
    assert_response :success
    assert_includes response.body, "Medical Insurance for Russia"

    get train_tickets_path
    assert_response :success

    get airport_transfer_path
    assert_response :success
    assert_includes response.body, "USD 220"
  end

  test "insurance request is created and emails are sent" do
    assert_difference -> { ServiceRequest.count }, 1 do
      assert_emails 2 do
        post service_requests_path, params: {
          kind: "insurance",
          service_request: {
            citizenship: "IN", date_from: (Date.current + 5).iso8601, date_to: (Date.current + 14).iso8601,
            surname: "Kumar", given_name: "Rahul", passport_number: "Z1234567", email: "rahul@example.com"
          }
        }
      end
    end

    assert_redirected_to insurance_path
    assert_equal 13.5, ServiceRequest.last.price.to_f
    assert_equal "Kumar Rahul", ServiceRequest.last.full_name
  end

  test "service forms ask for surname, given name and middle name like the main form" do
    [insurance_path, airport_transfer_path].each do |path|
      get path
      assert_select "input[name='service_request[surname]']"
      assert_select "input[name='service_request[given_name]']"
      assert_select "input[name='service_request[middle_name]']"
      assert_select "input[name='service_request[full_name]']", count: 0
      assert_select "#svcSurnameHint", count: 0
    end

    get insurance_path(tariff: "custom_20")
    assert_select "#svcSurnameHint", text: /dash/
    assert_select "#svcMiddleHint", text: /leave this field empty/
  end

  test "invalid request re-renders the form with errors" do
    post service_requests_path, params: { kind: "train", service_request: { email: "rahul@example.com" } }

    assert_response :unprocessable_entity
    assert_includes response.body, "Please check the form"
  end

  test "unknown kind is rejected" do
    post service_requests_path, params: { kind: "hack", service_request: { email: "a@example.com" } }

    assert_response :not_found
  end
end

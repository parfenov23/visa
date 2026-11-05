require "test_helper"

class ServiceRequestTest < ActiveSupport::TestCase
  def passport_file
    { io: File.open(Rails.root.join("test/fixtures/files/passport.png")), filename: "passport.png", content_type: "image/png" }
  end

  def insurance(attrs = {})
    ServiceRequest.new({ kind: "insurance", email: "a@example.com", citizenship: "IN",
                         full_name: "Rahul Kumar", passport_number: "Z1234567",
                         date_from: Date.current + 10, date_to: Date.current + 19 }.merge(attrs))
  end

  test "insurance price: 1.35 per day for India and Nepal, 2 for others" do
    india = insurance
    india.save!
    assert_equal 10, india.insurance_days
    assert_equal 13.5, india.price.to_f

    nepal = insurance(citizenship: "np")
    nepal.save!
    assert_equal 13.5, nepal.price.to_f

    china = insurance(citizenship: "CN")
    china.save!
    assert_equal 20.0, china.price.to_f
  end

  test "insurance period is 1 to 180 days" do
    assert insurance(date_to: Date.current + 10).valid?           # 1 день
    assert insurance(date_to: Date.current + 189).valid?          # 180 дней
    assert_not insurance(date_to: Date.current + 190).valid?      # 181 день
    assert_not insurance(date_to: Date.current + 9).valid?        # конец раньше начала
  end

  test "insurance start date can't be in the past" do
    assert_not insurance(date_from: Date.current - 1, date_to: Date.current + 5).valid?
  end

  test "insurance needs passport details or a passport copy" do
    req = insurance(full_name: nil, passport_number: nil)
    assert_not req.valid?

    req.passport_copy.attach(passport_file)
    assert req.valid?
  end

  test "train request requires cities, class and passport copy; price is not set" do
    req = ServiceRequest.new(kind: "train", email: "a@example.com", from_city: "Moscow", to_city: "Kazan",
                             date_from: Date.current + 3, seat_class: "coupe")
    assert_not req.valid?
    assert req.errors[:passport_copy].any?

    req.passport_copy.attach(passport_file)
    req.save!
    assert_nil req.price
    assert_equal "1", req.passengers
  end

  test "vip request costs 220 USD" do
    req = ServiceRequest.new(kind: "vip", email: "a@example.com", full_name: "Rahul Kumar",
                             date_from: Date.current + 3, arrival_time: "04:35", flight_number: "SU 233",
                             hotel_address: "Cosmos Hotel, Moscow", passengers: "2")
    req.passport_copy.attach(passport_file)
    req.save!

    assert_equal 220.0, req.price.to_f
    assert_equal "usd", req.currency
  end

  test "vip checklist values are booleans" do
    req = ServiceRequest.new(kind: "vip", docs_checked: "1", fsb_letter_ready: "0")

    assert_equal true, req.docs_checked
    assert_equal false, req.fsb_letter_ready
    assert_equal false, req.greeter_assigned
  end

  test "name is entered in parts and full_name is built from them" do
    req = insurance(full_name: nil, surname: " Sharma ", given_name: "Rahul", middle_name: "")
    req.save!
    assert_equal "Sharma Rahul", req.full_name
    assert_equal "Sharma", req.surname

    # Дальше full_name правят в админке — части его не перезаписывают.
    req.update!(full_name: "SHARMA RAHUL KUMAR")
    assert_equal "SHARMA RAHUL KUMAR", req.reload.full_name
  end

  test "vip request without a surname is invalid" do
    req = ServiceRequest.new(kind: "vip", email: "a@example.com", given_name: "",
                             date_from: Date.current + 3, arrival_time: "04:35", flight_number: "SU 233",
                             hotel_address: "Cosmos Hotel, Moscow")
    req.passport_copy.attach(passport_file)
    assert_not req.valid?
    assert req.errors[:surname].any?
  end
end

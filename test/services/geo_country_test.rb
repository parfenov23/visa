require "test_helper"

class GeoCountryTest < ActiveSupport::TestCase
  setup do
    @file = Rails.root.join("tmp/test_country_ranges_#{SecureRandom.hex(4)}.csv")
    source = <<~CSV
      1.0.0.0,1.0.0.255,AU
      14.139.0.0,14.139.255.255,IN
      27.34.0.0,27.34.127.255,NP
      2401:4900::,2401:4900:ffff:ffff:ffff:ffff:ffff:ffff,IN
      8.8.8.0,8.8.8.255,US
    CSV
    File.open(@file, "w") { |out| @count = GeoCountry.extract(StringIO.new(source), out) }
    @geo = GeoCountry.new(@file)
  end

  teardown do
    File.delete(@file) if File.exist?(@file)
  end

  test "keeps only India and Nepal ranges" do
    assert_equal 3, @count
  end

  test "looks up IPv4, IPv6 and IPv4-mapped addresses" do
    assert_equal "IN", @geo.lookup("14.139.5.5")
    assert_equal "NP", @geo.lookup("27.34.1.1")
    assert_equal "IN", @geo.lookup("2401:4900:1:2::5")
    assert_equal "IN", @geo.lookup("::ffff:14.139.5.5")
    assert_nil @geo.lookup("8.8.8.8")
    assert_nil @geo.lookup("not an ip")
  end

  test "missing file means no country" do
    assert_nil GeoCountry.new(Rails.root.join("tmp/nope.csv")).lookup("14.139.5.5")
    assert GeoCountry.stale?(Rails.root.join("tmp/nope.csv"))
  end
end

require "test_helper"

class SchedulerTest < ActiveSupport::TestCase
  class FakeRedis
    def initialize; @data = {}; end
    def exists?(key); @data.key?(key); end
    def set(key, value, nx: false, ex: nil)
      return false if nx && @data.key?(key)
      @data[key] = value
      true
    end
    def del(key); @data.delete(key); end
  end

  setup do
    @runs = 0
    job = Scheduler::Job.new(name: "test_job", at: "09:00", action: -> { @runs += 1 })
    @scheduler = Scheduler.new(jobs: [job], redis: FakeRedis.new, logger: Logger.new(nil))
  end

  test "runs a job once a day after its time" do
    @scheduler.tick(Time.zone.local(2026, 11, 3, 8, 59))
    assert_equal 0, @runs

    @scheduler.tick(Time.zone.local(2026, 11, 3, 9, 0))
    @scheduler.tick(Time.zone.local(2026, 11, 3, 15, 0))
    assert_equal 1, @runs

    @scheduler.tick(Time.zone.local(2026, 11, 4, 9, 1))
    assert_equal 2, @runs
  end

  test "failed job is retried at most 3 times a day" do
    attempts = 0
    job = Scheduler::Job.new(name: "failing", at: "09:00", action: -> { attempts += 1; raise "smtp down" })
    scheduler = Scheduler.new(jobs: [job], redis: FakeRedis.new, logger: Logger.new(nil))

    5.times { |i| scheduler.tick(Time.zone.local(2026, 11, 3, 9, i)) }

    assert_equal 3, attempts
  end

  test "periodic job runs at most once per interval" do
    runs = 0
    job = Scheduler::Job.new(name: "every_minute", every: 60, action: -> { runs += 1 })
    scheduler = Scheduler.new(jobs: [job], redis: FakeRedis.new, logger: Logger.new(nil))
    start = Time.zone.local(2026, 11, 3, 12, 0, 0)

    scheduler.tick(start)
    scheduler.tick(start + 30)
    scheduler.tick(start + 61)

    assert_equal 2, runs
  end
end

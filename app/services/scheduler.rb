# frozen_string_literal: true

# Простой планировщик фоновых задач: отдельный процесс (сервис `scheduler` в
# compose.production.yml), который раз в ~30 секунд проверяет, не пора ли
# запустить задачу. Каждая задача выполняется не чаще одного раза в день:
# отметка «выполнено» хранится в Redis (ключ живёт 3 дня). Если процесс
# перезапустился после времени запуска — задача выполнится сразу, в тот же день.
#
# Запуск: bin/scheduler
class Scheduler
  Job = Struct.new(:name, :at, :action, keyword_init: true)

  # Время — московское (config.time_zone).
  JOBS = [
    Job.new(name: "daily_invitations_report", at: "09:00",
            action: -> { InvitationsReport.daily.deliver })
  ].freeze

  MAX_ATTEMPTS_PER_DAY = 3
  TICK_SECONDS = 30

  def initialize(jobs: JOBS, redis: nil, logger: Rails.logger)
    @jobs     = jobs
    @redis    = redis
    @logger   = logger
    @memory   = {} # запасная отметка, если Redis недоступен
    @attempts = Hash.new(0)
  end

  def run
    log "started, jobs: #{@jobs.map { |j| "#{j.name}@#{j.at}" }.join(', ')}"
    loop do
      tick
      sleep TICK_SECONDS
    end
  end

  # Одна проверка расписания; отдельно — для тестов.
  def tick(now = Time.zone.now)
    @jobs.each { |job| run_job(job, now) if due?(job, now) }
  end

  private

  def due?(job, now)
    now.strftime("%H:%M") >= job.at &&
      @attempts[attempt_key(job, now)] < MAX_ATTEMPTS_PER_DAY &&
      !done?(job, now)
  end

  def run_job(job, now)
    return unless mark_done(job, now)

    log "#{job.name}: running"
    job.action.call
    log "#{job.name}: done"
  rescue StandardError => e
    @attempts[attempt_key(job, now)] += 1
    unmark_done(job, now)
    log "#{job.name}: failed (attempt #{@attempts[attempt_key(job, now)]}): #{e.class}: #{e.message}", :error
  end

  def done_key(job, now)
    "scheduler:#{job.name}:#{now.to_date.iso8601}"
  end
  alias attempt_key done_key

  def done?(job, now)
    with_redis(-> { @memory[done_key(job, now)] }) { |r| r.exists?(done_key(job, now)) }
  end

  # true — если отметку поставили мы (задачу ещё никто не выполнял сегодня).
  def mark_done(job, now)
    key = done_key(job, now)
    with_redis(-> { @memory[key] ? false : (@memory[key] = true) }) do |r|
      r.set(key, Time.zone.now.iso8601, nx: true, ex: 3 * 24 * 3600)
    end
  end

  def unmark_done(job, now)
    key = done_key(job, now)
    @memory.delete(key)
    with_redis(-> {}) { |r| r.del(key) }
  end

  def with_redis(fallback)
    yield redis
  rescue Redis::BaseError => e
    log "redis unavailable, using in-memory marks: #{e.message}", :warn unless @redis_warned
    @redis_warned = true
    fallback.call
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/2"))
  end

  def log(message, level = :info)
    line = "[scheduler] #{message}"
    @logger.public_send(level, line)
    puts line
  end
end

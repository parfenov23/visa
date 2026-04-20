redis_url = ENV.fetch("RACK_ATTACK_REDIS_URL", "redis://localhost:6379/2")
Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)

Rack::Attack.throttle("invitations/ip", limit: 3, period: 1.hour) do |req|
  req.ip if req.post? && req.path == "/invitations"
end

Rack::Attack.throttled_responder = lambda do |request|
  retry_after = (request.env["rack.attack.match_data"] || {})[:period].to_i
  body = "Too many requests from your IP. Please try again later."
  [429, { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s }, [body]]
end
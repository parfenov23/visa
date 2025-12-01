#!/usr/bin/env puma
environment ENV['RAILS_ENV']
pidfile "tmp/pids/puma.pid"
if ENV['RAILS_ENV'] == 'development'
  threads 2, 4
  workers 2
else
  threads 2, 16
  workers 2
end

activate_control_app

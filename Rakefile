# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require_relative 'config/application'
Rails.application.load_tasks

# Избегаем вызова `db:test:prepare` во время `rails test`
# `db:test:prepare`` вызывает `db:test:load`
# `db:test:load` пересоздаёт тестовую бд из schema.rb
# В schema.rb нет materialized views
# Из-за db:test:load пропадает materialized views и ломается функциональность в тестах
# https://stackoverflow.com/a/1101325
# https://medium.com/wolox/activerecord-postgresql-materialized-views-9a9ef56b5a8d

lock "~> 3.19.2"

set :application, "visa"
set :repo_url, "git@github.com:parfenov23/visa.git"

set :deploy_to, "/home/visa"
set :keep_releases, 5

append :linked_files, ".env.production"
append :linked_dirs, "log", "storage"

namespace :deploy do
  desc "Build and start containers"
  task :docker_up do
    on roles(:app) do
      within release_path do
        execute :docker, "compose -f compose.production.yml pull || true"
        execute :docker, "compose -f compose.production.yml build"
        execute :docker, "compose -f compose.production.yml up -d"
      end
    end
  end

  desc "Run migrations in container"
  task :migrate_in_docker do
    on roles(:db) do
      within release_path do
        execute :docker, "compose -f compose.production.yml run --rm web bundle exec rails db:migrate"
      end
    end
  end

  desc "Restart web container"
  task :restart_docker do
    on roles(:app) do
      within release_path do
        execute :docker, "compose -f compose.production.yml restart web"
      end
    end
  end

  after :publishing, :docker_up
  after :docker_up, :migrate_in_docker
  after :migrate_in_docker, :restart_docker
end

namespace :deploy do
  task :assets_precompile_in_docker do
    on roles(:app) do
      within release_path do
        execute :docker, "compose -f compose.production.yml run --rm web bundle exec rails assets:precompile"
      end
    end
  end

  before :docker_up, :assets_precompile_in_docker
end
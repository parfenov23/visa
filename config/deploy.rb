lock "~> 3.19.2"

set :application, "visa"
set :repo_url, "git@github.com:parfenov23/visa.git"

set :deploy_to, "/home/visa"
set :keep_releases, 5

append :linked_files, ".env.production"
append :linked_dirs, "log", "storage"

set :compose_file, "compose.production.yml"
set :compose_project_name, fetch(:application) # "visa"

def compose(cmd)
  "compose -p #{fetch(:compose_project_name)} -f #{fetch(:compose_file)} #{cmd}"
end

namespace :deploy do
  desc "Precompile assets in container into shared volume"
  task :assets_precompile_in_docker do
    on roles(:app) do
      within release_path do
        execute :docker, compose("run --rm web bundle exec rails assets:precompile")
      end
    end
  end

  desc "Build and start containers"
  task :docker_up do
    on roles(:app) do
      within release_path do
        execute :docker, compose("pull || true")
        execute :docker, compose("build")
        execute :docker, compose("up -d")
      end
    end
  end

  desc "Run migrations in container"
  task :migrate_in_docker do
    on roles(:db) do
      within release_path do
        execute :docker, compose("run --rm web bundle exec rails db:migrate")
      end
    end
  end

  desc "Restart web container"
  task :restart_docker do
    on roles(:app) do
      within release_path do
        execute :docker, compose("restart web")
      end
    end
  end

  before :docker_up, :assets_precompile_in_docker
  after  :publishing, :docker_up
  after  :docker_up,  :migrate_in_docker
  after  :migrate_in_docker, :restart_docker
end
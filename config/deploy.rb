lock '3.17.3'

set :deploy_to, '/var/www/telega_stat'
prod_compose_yml = " -f #{current_path}/compose.yml -f #{current_path}/config/docker/rails/compose.production.yml"
set :prod_compose_yml, prod_compose_yml
set :prod_compose_yml_alternate, (prod_compose_yml << " -f #{current_path}/config/docker/rails/compose.yml")

prod2_compose_yml = " -f #{current_path}/compose.production2.yml -f #{current_path}/config/docker/rails/compose.production2.yml"
set :prod2_compose_yml, prod2_compose_yml
set :prod2_compose_yml_alternate, (prod2_compose_yml << " -f #{current_path}/config/docker/rails/compose.yml")

staging_compose_yml = " -f #{current_path}/compose.staging.yml -f #{current_path}/config/docker/rails/compose.staging.yml"
set :staging_compose_yml, staging_compose_yml
set :staging_compose_yml_alternate, (staging_compose_yml << " -f #{current_path}/config/docker/rails/compose.yml")

# Индивидуальные опции для каждого сервера production, production2 и staging
set :prod_options, proc {
  {
    docker_compose_yml: fetch(:prod_compose_yml),
    docker_compose_yml_alternate: fetch(:prod_compose_yml_alternate),
    stage: 'production'
  }
}

set :prod2_options, proc {
  {
    docker_compose_yml: fetch(:prod2_compose_yml),
    docker_compose_yml_alternate: fetch(:prod2_compose_yml_alternate),
    stage: 'production2'
  }
}

set :staging_options, proc {
  {
    docker_compose_yml: fetch(:staging_compose_yml),
    docker_compose_yml_alternate: fetch(:staging_compose_yml_alternate),
    stage: 'staging'
  }
}

set :application, 'telega_stat'
# set :user, 'deployer'

set :repo_url, 'git@gitlab.telega.in:telega-stat/telega_stat.git'
if ENV['branch'].nil? || ENV['branch'].empty?
  set :branch, 'main'
else
  set :branch, ENV['branch']
end

set :repository_cache, 'git_cache'
set :log_level, :error
set :keep_releases, 15
set :run_tests_before_deploy, false
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

set :stage, 'production' if fetch(:stage).to_s == 'both_production'

# compose_files =   "-f #{fetch(:deploy_to)}/current/compose.yml"
if fetch(:stage).to_s == 'production'
  compose_files = "-f #{fetch(:deploy_to)}/current/compose.yml"
else
  compose_files = "-f #{fetch(:deploy_to)}/current/compose.#{fetch(:stage)}.yml"
end

compose_files << " -f #{fetch(:deploy_to)}/current/config/docker/rails/compose.#{fetch(:stage)}.yml"
set :docker_compose_yml, compose_files

compose_files << " -f #{fetch(:deploy_to)}/current/config/docker/rails/compose.yml"
set :docker_compose_yml_alternate, compose_files

set :docker_compose_permanent_yml, "-f #{fetch(:deploy_to)}/current/compose.permanent.yml"

#database:
set :keep_db_backups, 15
set :backup_db_on_deploy, true
set :backups_path, "#{fetch(:deploy_to)}/shared/db/pg/backups"
secrets = YAML.load(`DD_TRACE_STARTUP_LOGS=false rails credentials:show --environment #{fetch(:stage)}`)
set :database,               secrets['postgres']['database']
set :database_user,          secrets['postgres']['username']
set :database_password,      secrets['postgres']['password']
set :elasticsearch_host,     secrets['elasticsearch']['host']
set :elasticsearch_username, secrets['elasticsearch']['username']
set :elasticsearch_password, secrets['elasticsearch']['password']

p "start check password #{ENV['SUDO_PASSWORD']}\r"

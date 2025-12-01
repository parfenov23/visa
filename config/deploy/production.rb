server "92.205.109.107", user: "deploy", roles: %w[app db web], primary: true

set :branch, "main"
set :rails_env, "production"
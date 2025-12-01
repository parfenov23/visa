namespace :nginx do
  desc "Upload nginx config and reload"
  task :setup do
    on roles(:web) do
      avail = "/etc/nginx/sites-available/#{fetch(:application)}"
      enabled = "/etc/nginx/sites-enabled/#{fetch(:application)}"

      upload! "config/nginx/myapp.conf", "/tmp/#{fetch(:application)}.nginx.conf"

      execute :sudo, :mv, "/tmp/#{fetch(:application)}.nginx.conf", avail
      execute :sudo, :ln, "-sf", avail, enabled

      # выключаем default если есть
      execute :sudo, :rm, "-f", "/etc/nginx/sites-enabled/default"

      execute :sudo, :nginx, "-t"
      execute :sudo, :systemctl, "reload nginx"
    end
  end
end

after "deploy:publishing", "nginx:setup"
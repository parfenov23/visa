Rails.application.routes.draw do
  # Отдельный домен для QR-верификации (VERIFY_DOMAIN, напр. fortunatravel.in).
  # На нём доступна только страница /verify/:token — любые другие пути,
  # включая корень, явно отдают 404. Основной сайт живёт на своём домене.
  verify_only_host = lambda do |req|
    domain = ENV["VERIFY_DOMAIN"].presence
    domain.present? && (req.host == domain || req.host.end_with?(".#{domain}"))
  end

  # Публичная страница верификации туриста по QR-коду из приглашения.
  # Без ограничения по хосту: старые QR ведут на основной домен и должны работать.
  get '/verify/:token', to: 'invitations#verify', as: :verify

  # Всё остальное на QR-домене — страница 404.
  not_found = lambda do |_env|
    page = Rails.public_path.join("404.html")
    body = page.exist? ? page.read : "Not Found"
    [404, { "Content-Type" => "text/html" }, [body]]
  end
  match '(*path)', to: not_found, via: :all, constraints: verify_only_host, format: false

  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)
  resources :invitations, only: [:create, :show]
  get '/russ_tourist', to: 'home#russ_tourist'
  # Короткий алиас маркетинговой ссылки: /in — главная с тарифом custom_20
  # (эквивалент /?tariff=custom_20, URL в адресной строке остаётся /in).
  get '/in', to: 'home#index', defaults: { tariff: 'custom_20' }
  root to: 'home#index'
end
Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)
  resources :invitations, only: [:create, :show]
  get '/russ_tourist', to: 'home#russ_tourist'
  root to: 'home#index'
end

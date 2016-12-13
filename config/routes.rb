Rails.application.routes.draw do
  root to: 'provision#new'
  resources :provision, only: [:new, :create, :index]
end

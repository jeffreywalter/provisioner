Rails.application.routes.draw do
  resources :passwords, controller: "clearance/passwords", only: [:create, :new]
  resource :session, controller: "clearance/sessions", only: [:create]

  resources :users, controller: "clearance/users", only: [:create] do
    resource :password,
      controller: "clearance/passwords",
      only: [:create, :edit, :update]
  end

  get "/sign_in" => "clearance/sessions#new", as: "sign_in"
  delete "/sign_out" => "clearance/sessions#destroy", as: "sign_out"
  get "/sign_up" => "clearance/users#new", as: "sign_up"
  root to: 'provision#new'
  resources :provision, only: [:new, :index]
  get '/provision/stream', to: "provision#stream"

  resources :duplicate, only: [:new]
  get '/duplicate/stream', to: "duplicate#stream"
  get '/duplicate/properties', to: "duplicate#properties"

  resources :clone, only: [:new]
  get '/clone/stream', to: "clone#stream"
  get '/clone/properties', to: "clone#properties"

  post '/rule_callback', to: 'copy_down#callback'

  resources :copy_down, only: [:index, :show, :create, :new]
end

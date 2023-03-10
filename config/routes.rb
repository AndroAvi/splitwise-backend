Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :users, only: %i[create index]
  resources :groups, only: %i[create index show update] do
    resources :expenses, only: %i[create index]
  end
  put '/groups/:id/settleup', to: 'groups#settle_up'
  post '/users/login', to: 'users#login'
  get '/users/search', to: 'users#search'
  # Defines the root path route ('/')
  # root 'articles#index'
end

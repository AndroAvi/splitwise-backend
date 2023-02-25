Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :users, only: %i[create index]
  resources :groups, only: %i[create index]
  resources :expenses, only: %i[create]
  post '/users/login', to: 'users#login'
  put '/groups/users', to: 'groups#add_user'
  get '/users/search', to: 'users#search'
  # Defines the root path route ('/')
  # root 'articles#index'
end

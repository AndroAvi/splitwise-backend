Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :users, only: %i[create index]
  post '/users/login', to: 'users#login'
  # Defines the root path route ('/')
  # root 'articles#index'
end

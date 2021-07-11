Rails.application.routes.draw do
    
  #devise_for :users
  root 'pages#home'
  get 'about' => 'pages#about'
  get 'menu' => 'pages#menu'
  #resources :orders
    
end

Rails.application.routes.draw do
    
  root 'pages#home'
  get 'about' => 'pages#about'
  get 'menu' => 'pages#menu'
  resources :orders
    
end

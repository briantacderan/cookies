Rails.application.routes.draw do
  devise_for :users
  resources :pages
  root 'pages#home'
  get 'about' => 'pages#about'
  get 'menu' => 'pages#menu'
  namespace :stripe do
    resources :checkouts
    post 'webhook' => 'checkouts#webhook'
    post 'add' => 'checkouts#new'
    get 'cart' => 'checkouts#show'
    get 'finalize', to: 'checkouts#create'
    get 'thanks' => 'checkouts#thanks'
    delete 'restart' => 'checkouts#destroy'
  end
  resources :subscriptions
end

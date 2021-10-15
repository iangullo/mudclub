Rails.application.routes.draw do
  root to: "home#index"
  get 'home/index'
  devise_for :users
  resources :users
  resources :teams
  resources :drills
  resources :training_slots
  resources :coaches do
    collection do
      post :import
    end
  end
  resources :people do
    collection do
      post :import
    end
  end
  resources :players do
    collection do
      post :import
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end

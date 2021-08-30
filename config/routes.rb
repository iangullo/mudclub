Rails.application.routes.draw do
  devise_for :users
  root to: "home#index"
  resources :training_sessions
  resources :teams
  resources :drills
  resources :training_slots
  resources :coaches
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

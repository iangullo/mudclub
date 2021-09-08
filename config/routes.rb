Rails.application.routes.draw do
  root to: "teams#index"
  resources :training_slots
  resources :drills
  resources :teams
  resources :coaches
  resources :players
  resources :people
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end

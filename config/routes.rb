Rails.application.routes.draw do
  root to: "home#index"
  get 'home/index'
  devise_for :users, :skip => [:registrations]
  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users' => 'devise/registrations#update', :as => 'user_registration'
  end
  resources :users
  resources :slots
  resources :locations
  resources :events
  resources :seasons do
    resources :locations
    resources :slots
    resources :events
  end
  resources :teams do
    get 'edit_roster', on: :member
    get 'edit_coaches', on: :member
    get 'coaching', on: :member
    get 'targets', on: :member
    get 'edit_targets', on: :member
    get 'plan', on: :member
    get 'edit_plan', on: :member
    resources :events
  end
  resources :drills
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

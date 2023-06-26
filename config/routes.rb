# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
Rails.application.routes.draw do
  resources :categories
  resources :divisions
  root to: "home#index"
  get 'home/index'
  get 'home/edit'
  devise_for :users, :skip => [:registrations]
  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users' => 'devise/registrations#update', :as => 'user_registration'
  end
  resources :users do
    get 'actions', on: :member
    get 'clear_actions', on: :member
  end
  resources :slots
  resources :locations
  resources :events do
    get 'load_chart', on: :member
    get 'show_task', on: :member
    get 'add_task', on: :member
    get 'edit_task', on: :member
    get 'attendance', on: :member
    get 'stats', on: :member
    get 'edit_stats', on: :member
  end
  resources :seasons do
    resources :locations
    resources :slots
    resources :events
  end
  resources :teams do
    get 'roster', on: :member
    get 'edit_roster', on: :member
    get 'targets', on: :member
    get 'edit_targets', on: :member
    get 'plan', on: :member
    get 'edit_plan', on: :member
    get 'slots', on: :member
    get 'attendance', on: :member
    resources :events
  end
  resources :drills do
    get 'versions', on: :member
  end
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

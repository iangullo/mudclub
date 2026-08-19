# MudClub - Modular Rails application for managing sports clubs.
# Copyright (C) 2026  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
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
# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  #-------------------------------------
  # Core service routes
  #-------------------------------------
  root to: "home#index"
  get "home/about"
  get "home/log"
  get "home/clear"
  get "home/index"
  get "home/server"
  devise_for :users, skip: [ :registrations ]

  as :user do
    get "users/edit" => "devise/registrations#edit", :as => "edit_user_registration"
    put "users" => "devise/registrations#update", :as => "user_registration"
  end

  resources :users do
    get "actions", on: :member
    get "clear_actions", on: :member
  end

  resources :sports do
    get :rules, on: :member
    resources :categories
    resources :divisions
  end

  #-------------------------------------
  # Clubs are the main organizational units
  #-------------------------------------
  resources :clubs do
    # Facilities available to the club
    get :locations, to: "locations#index"

    # Administrative
    resources :members, controller: :memberships, except: :destroy do
      resources :assignments, only: %i[show edit update]
    end

    # Club operational roles
    resources :assignments, only: %i[index new create],
              param: :membership_kind

    # Calendar objects
    resources :slots
    resources :events

    # Club teams
    resources :teams do
      resources :assignments, only: %i[show new edit create update]
      # resource :volunteers, only: %i[new create]

      # Team-specific actions
      get :attendance
      get :plan
      get :edit_plan
      get :roster
      get :edit_roster
      get :slots
      get :targets
      get :edit_targets

      # Team calendar
      resources :events do
        get :attendance
        get :copy
        get :load_chart
        get :player_stats
        get :edit_player_stats
        get :show_task
        get :add_task
        get :edit_task
      end
    end
  end

  #-------------------------------------
  # Training domain routes
  #-------------------------------------
  resources :drills do
    member do
      get :versions
      get :edit_diagram	# /drills/:id/edit_diagram?step_id=X&order=Y
      get :load_diagram # /drills/:id/load_diagram?step_id=X&order=Y
      patch :update_diagram # /drills/:id/update_diagram?step_id=X
    end
  end

  resources :locations, except: [ :index ]

  resources :seasons

  # DEPRECATED routes
  # resources :people
  resources :coaches, except: [ :index ] do
    collection do
      post :import
    end
  end

  resources :players, except: [ :index ] do
    collection do
      post :import
    end
  end
end

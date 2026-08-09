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
		get :events, to: "events#index"	# club calendar
		get :locations, to: "locations#index"	# club locations
		get :slots, to: "slots#index"	# club slots

		# Administrative
		resources :members, controller: :memberships, except: :destroy do
			resources :assignments, only: %i[show edit update]
		end

		# Club operational roles
		resources :assignments, only: %i[index new create],
							param: :membership_kind

		# Club teams
		resources :teams do
			resources :assignments, only: %i[new create]
			# resource :volunteers, only: %i[new create]
			member do
				get :attendance
				get :events
				get :plan
				get :edit_plan
				get :roster
				get :edit_roster
				get :slots
				get :targets
				get :edit_targets
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

	#-------------------------------------
	# Pending re-arrangement with 2.0 philosophy
	#-------------------------------------
	resources :events, except: [ :index ] do
		member do
			get "copy"
			get "load_chart"
			get "show_task"
			get "add_task"
			get "edit_task"
			get "attendance"
			get "player_stats"
			get "edit_player_stats"
		end
	end

	resources :locations, except: [ :index ]

	resources :seasons

	resources :slots, except: [ :index ]

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

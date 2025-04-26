# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
	root to: "home#index"
	get 'home/about'
	get 'home/log'
	get 'home/clear'
	get 'home/index'
	get 'home/server'
	devise_for :users, :skip => [:registrations]
	as :user do
		get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
		put 'users' => 'devise/registrations#update', :as => 'user_registration'
	end
	resources :clubs do
		get 'coaches', to: 'coaches#index'	# team event calendar
		get 'events', to: 'events#index'	# team event calendar
		get 'locations', to: 'locations#index'	# team event calendar
		get 'players', to: 'players#index'	# team event calendar
		get 'slots', to: 'slots#index'	# team event calendar
		get 'teams', to: 'teams#index'	# team event calendar
	end
	resources :coaches, except: [:index] do
		collection do
			post :import
		end
	end
	resources :drills do
		member do
			get :versions
			get   :edit_diagram   # /drills/:id/edit_diagram?step_id=X
			patch :update_diagram # /drills/:id/update_diagram?step_id=X
		end
	end
	resources :events, except: [:index] do
		member do
			get 'copy'
			get 'load_chart'
			get 'show_task'
			get 'add_task'
			get 'edit_task'
			get 'attendance'
			get 'player_stats'
			get 'edit_player_stats'
		end
	end
	resources :locations, except: [:index]
	resources :players, except: [:index] do
		collection do
			post :import
		end
	end
	resources :seasons
	resources :slots, except: [:index]
	resources :sports do
		get 'rules', on: :member
		resources :categories
		resources :divisions
	end
	resources :teams, except: [:index] do
		get 'events', to: 'events#index'	# team event calendar
		member do
			get 'attendance'
			get 'plan'
			get 'edit_plan'
			get 'roster'
			get 'edit_roster'
			get 'slots'
			get 'targets'
			get 'edit_targets'
		end
	end
	resources :users do
		get 'actions', on: :member
		get 'clear_actions', on: :member
	end
end

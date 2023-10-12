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
# frozen_string_literal: true

# TopbarComponent - dynamic display of application top bar as ViewComponent
class TopbarComponent < ApplicationComponent
	def initialize(user:, login:, logout:)
		clubperson = Person.find(0)
		@clublogo  = clubperson.logo
		@clubname  = clubperson.nick
		@tabcls    = 'hover:bg-blue-700 hover:text-white focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200 whitespace-nowrap shadow rounded ml-2 px-2 py-2 rounded-md font-semibold'
		@lnkcls    = 'no-underline block pl-2 pr-2 py-2 hover:bg-blue-700 hover:text-white whitespace-nowrap'
		@profcls   = 'align-middle rounded-full min-h-8 min-w-8 align-middle hover:bg-blue-700 hover:ring-4 hover:ring-blue-200 focus:ring-4 focus:ring-blue-200'
		@logincls  = 'login_button rounded hover:bg-blue-700 max-h-8 min-h-6'
		@u_logged  = user&.present?
		load_menus(user:, login:, logout:)
	end

	private
	# load menu buttons
	def load_menus(user:, login:, logout:)
		@profile  = set_profile(user:, login:, logout:)
		if user
			I18n.locale = user.locale.to_sym
			@menu_tabs  = menu_tabs(user)
		end
		@prof_tab = prof_tab(user)
		@ham_menu = set_hamburger_menu if user
	end

	#right hand profile menu
	def set_profile(user:, login:, logout:)
		res  = {
			profile: menu_link(label: I18n.t("user.profile"), url: user, kind: "modal"),
			login: menu_link(label: I18n.t("action.login"), url: login),
			logout: menu_link(label: I18n.t("action.logout"), url: logout, kind: "delete"),
			closed: {icon: "login.svg", url: login, class: @logincls}
		}
		res[:open] = {icon: user.picture, url: login, class: @logincls} if user
		res
	end

	def menu_tabs(user)
		if user.admin?
			a_menu = admin_menu(user)
			if user.is_coach?
				menu  = manager_menu(user)
				menu += a_menu
			else
				a_menu
			end
		elsif user.manager?
			manager_menu(user)
		elsif user.is_coach?
			coach_menu(user)
		elsif user.is_player?
			player_menu(user)
		else
			user_menu(user)
		end
	end

	def prof_tab(user)
		if user
			res = {kind: "menu", name: "profile", icon: user.picture, options:[], class: @profcls, i_class: "rounded-full", size: "30x30"}
			res[:options] << menu_link(label: @profile[:profile][:label], url: @profile[:profile][:url], class: @profcls)
			res[:options] << menu_link(label: @profile[:logout][:label], url: @profile[:logout][:url], class: @profcls)
		else
			res           = menu_link(label: nil, url: @profile[:login][:url], class: @profile[:closed][:class])
			res[:icon]    = @profile[:closed][:icon]
			res[:name]    = "profile"
			res[:i_class] = @logincls
		end
		res
	end

	def set_hamburger_menu
		res = {kind: "menu", name: "hamburger", ham: true, options:[], class: @tabcls}
		@menu_tabs.each do |m_opt|
			res[:options] << m_opt
		end
		res
	end

	def menu_link(label:, url:, class: @lnkcls, kind: "normal")
		case kind
		when "normal"
			l_data = {turbo_action: "replace"}
		when "modal"
			l_data = {turbo_frame: "modal"}
		when "delete"
			l_data = {turbo_method: :delete}
		end
		{kind:, label:, url:, class:, data: l_data }
	end

	# menu to manage sports
	def sport_menu
		s_menu = {kind: "menu", name: "sports", label: I18n.t("sport.many"), options:[]}
		Sport.all.each do |sport|
			s_path = "/sports/#{sport.id}"
			s_menu[:options] << menu_link(label: sport.to_s, url: "#{s_path}")
		end
		s_menu
	end

	# menu buttons for mudclub admins
	def admin_menu(user)
		c_menu = {kind: "menu", name: "admin", label: I18n.t("action.admin"), options:[], class: @tabcls}
		c_menu[:options] << menu_link(label: I18n.t("person.name"), url: '/home/edit', kind: "modal")
		c_menu[:options] << sport_menu
		c_menu[:options] << menu_link(label: I18n.t("user.many"), url: '/users')
		c_menu[:options] << menu_link(label: I18n.t("user.actions"), url: '/home/actions')
		[c_menu]
	end

	# menu buttons for club managers
	def manager_menu(user)
		m_menu = {kind: "menu", name: "manage", label: @clubname, options:[], class: @tabcls}
		m_menu[:options] << menu_link(label: I18n.t("season.single"), url: '/seasons')
		m_menu[:options] << menu_link(label: I18n.t("player.many"), url: '/players')
		m_menu[:options] << menu_link(label: I18n.t("coach.many"), url: '/coaches')
		m_menu[:options] << menu_link(label: I18n.t("team.many"), url: '/teams') unless user.is_coach?
		m_menu[:options] << menu_link(label: I18n.t("location.many"), url: '/locations')
		menu = [m_menu]
		if user.is_coach?
			menu += team_menu(user)
			menu << menu_link(label: I18n.t("drill.many"), url: '/drills')
		end
		menu
	end

	# menu buttons for coaches
	def coach_menu(user)
		menu = team_menu(user)
		menu += [
			menu_link(label: I18n.t("drill.many"), url: '/drills'),
			menu_link(label: I18n.t("player.many"), url: '/players'),
			menu_link(label: I18n.t("location.many"), url: '/locations')
		]
	end

	def player_menu(user)
		menu = team_menu(user)
		menu
	end

	def user_menu(user)
		menu = []
		menu
	end

	def team_menu(user)
		menu    = []
		m_teams = {kind: "menu", name: "teams", label: I18n.t("team.many"), options:[], class: @tabcls}
		u_teams = user.team_list
		if u_teams
			slast = Season.latest
			if slast
				u_teams.each { |team| m_teams[:options] << menu_link(label: team.name, url: '/teams/'+ team.id.to_s) if team.season==slast}
			end
		end
		if m_teams[:options].empty?
			menu << menu_link(label: I18n.t("team.many"), url: '/teams')
		else
			m_teams[:options] << menu_link(label: I18n.t("scope.all"), url: '/teams')
			menu << m_teams
		end
	end
end

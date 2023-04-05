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
		@u_logged  = user.try(:present?)
		load_menus(user:, login:, logout:)
	end

	private
	# load menu buttons
	def load_menus(user:, login:, logout:)
		@profile  = set_profile(user:, login:, logout:)
		if user
			I18n.locale = user.locale.to_sym
			@menu_tabs  = menu_tabs(user)
			@admin_tab  = admin_tab(user) if user.admin? or user.is_coach?
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
		res     = []
		m_teams = {kind: "menu", name: "teams", label: I18n.t("team.many"), options:[], class: @tabcls}
		if user.teams
			slast = Season.latest
			if slast
				user.teams.each { |team| m_teams[:options] << menu_link(label: team.name, url: '/teams/'+ team.id.to_s) if team.season==slast}
			end
		end
		m_teams[:options] << menu_link(label: I18n.t("scope.all"), url: '/teams')
		res << m_teams unless m_teams[:options].empty?
		if user.is_coach?
			res << menu_link(label: I18n.t("drill.many"), url: '/drills')
			res << menu_link(label: I18n.t("player.many"), url: '/players') unless user.admin?
			res << menu_link(label: I18n.t("coach.many"), url: '/coaches') unless user.admin?
			res << menu_link(label: I18n.t("location.many"), url: '/locations') unless user.admin?
			res << menu_link(label: I18n.t("slot.many"), url: '/slots') unless user.admin?
		end
		res
	end

	def admin_tab(user)
		if user.admin?
			res = {kind: "menu", name: "admin", label: I18n.t("action.admin"), options:[], class: @tabcls}
			c_opts = {name: "club-menu", label: @clubname, options:[]}
			c_opts[:options] << menu_link(label: I18n.t("person.name"), url: '/home/edit', kind: "modal")
			c_opts[:options] << menu_link(label: I18n.t("season.many"), url: '/seasons')
			c_opts[:options] << menu_link(label: I18n.t("category.many"), url: '/categories')
			c_opts[:options] << menu_link(label: I18n.t("division.many"), url: '/divisions')
			c_opts[:options] << menu_link(label: I18n.t("player.many"), url: '/players')
			c_opts[:options] << menu_link(label: I18n.t("coach.many"), url: '/coaches')
			c_opts[:options] << menu_link(label: I18n.t("team.many"), url: '/teams') unless user.is_coach?
			res[:options] << c_opts
			res[:options] << menu_link(label: I18n.t("user.many"), url: '/users')
			res[:options] << menu_link(label: I18n.t("location.many"), url: '/locations')
		end
		res
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
		@menu_tabs.each { |m_opt|
			if m_opt[:kind]=="menu" # let's break it down
				m_opt[:options].each {|s_opt|
					a_opt = s_opt.dup
					a_opt[:label] = I18n.t("team.many") if s_opt[:url]=="/teams"
					res[:options] << a_opt
				}
			else
				res[:options] << m_opt
			end
		}
		@admin_tab[:options].each { |m_adm|
			a_opt = m_adm.dup
			a_opt[:name]="h_#{m_adm[:name]}"
			res[:options] << a_opt
		} if @admin_tab
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
end

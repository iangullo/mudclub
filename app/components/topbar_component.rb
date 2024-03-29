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
	def initialize(user:, logo:, nick:, home:, login:, logout:)
		@clublogo  = logo
		@clubname  = nick
		@tabcls    = 'hover:bg-blue-700 hover:text-white focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200 whitespace-nowrap rounded ml-2 px-2 py-2 rounded-md font-semibold'
		@lnkcls    = 'no-underline block pl-2 pr-2 py-2 hover:bg-blue-700 hover:text-white whitespace-nowrap'
		@profcls   = 'align-middle rounded-full min-h-8 min-w-8 align-middle hover:bg-blue-700 hover:ring-4 hover:ring-blue-200 focus:ring-4 focus:ring-blue-200'
		@logincls  = 'login_button rounded hover:bg-blue-700 max-h-8 min-h-6'
		@u_logged  = user&.present?
		load_menus(user:, home:, login:, logout:)
	end

	private
	# load menu buttons
	def load_menus(user:, home:, login:, logout:)
		@profile  = set_profile(user:, home:, login:, logout:)
		if user.present?
			I18n.locale = user.locale.to_sym
			@menu_tabs  = menu_tabs(user)
			@ham_menu   = set_hamburger_menu
		end
		@prof_tab = prof_tab(user)
	end

	# wrapper to define a dropdown menu hash - :options returned as [] if received as nil
	def menu_drop(name, label: nil, options: [], ham: nil)
		{kind: "menu", name:, label:, options:, ham:}
	end

	def menu_link(label:, url:, class: "no-underline block pl-2 pr-2 py-2 hover:bg-blue-700 hover:text-white whitespace-nowrap", kind: "normal")
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

	def menu_tabs(user)
		@menu_tabs = team_menu(user)
		if user.admin?
			admin_menu(user)
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
		if user.present?
			options = []
			options << menu_link(label: @profile[:profile][:label], url: @profile[:profile][:url], class: @profcls)
			options << menu_link(label: @profile[:logout][:label], url: @profile[:logout][:url], class: @profcls)
			options << menu_link(label: I18n.t("server.about"), url: '/home/about', kind: "modal", class: @profcls) unless (user.admin? || user.manager?)
			res = menu_drop("profile", options:)
			res.merge!({icon: user.picture, class: @profcls, i_class: "rounded", size: "30x30"})
			DropdownComponent.new(button: res)
		else
			res = {kind: "menu", label: I18n.t("action.login"), url: @profile[:login][:url], class: @profile[:closed][:class]}
			res.merge!({icon: @profile[:closed][:icon], name: "profile", i_class: @logincls})
			ButtonComponent.new(button: res)
		end
	end

	def set_hamburger_menu
		options = []
		@menu_tabs.each do |m_opt|
			h_opt = m_opt.deep_dup
			if h_opt[:options]
				h_opt[:sub]  = true
				h_opt[:name] = "h_#{h_opt[:name]}"
				h_opt[:options]&.each do |s_opt|	# 2nd level menus
					if s_opt[:options]
						s_opt[:sub]  = true
						s_opt[:name] = "h_#{s_opt[:name]}"
						s_opt[:options]&.each do |t_opt| # 3rd level
							if t_opt[:options]
								t_opt[:sub]  = true
								t_opt[:name]  = "h_#{t_opt[:name]}"
							end
						end
					end
				end
			end
			options << h_opt
		end
		DropdownComponent.new(button: menu_drop("hamburger", ham: true, options:))
	end

	# right hand profile menu
	def set_profile(user:, home:, login:, logout:)
		res  = {
			profile: menu_link(label: I18n.t("user.profile"), url: home, kind: "modal"),
			login: menu_link(label: I18n.t("action.login"), url: login),
			logout: menu_link(label: I18n.t("action.logout"), url: logout, kind: "delete"),
			closed: {icon: "login.svg", url: login, class: @logincls}
		}
		res[:open] = {icon: user.picture, url: login, class: @logincls} if user.present?
		res
	end

	# menu buttons for mudclub admins
	def admin_menu(user)
		options = []
		options << manager_menu(user) if user.is_manager?
		options << server_menu(user) if user.admin?
		options << menu_link(label: I18n.t("server.about"), url: '/home/about', kind: "modal")
		@menu_tabs << menu_drop("admin", label: I18n.t("action.admin"), options:)
	end

	# menu buttons for coaches
	def coach_menu(user, pure=true)
		@menu_tabs << menu_link(label: I18n.t("drill.many"), url: '/drills')
		@menu_tabs << menu_link(label: I18n.t("player.many"), url: "/clubs/#{user.club_id}/players") if pure
	end

	# menu buttons for club managers
	def manager_menu(user)
		coach_menu(user, pure=false) if user.is_coach?
		if user.is_manager?
			cluburl = "/clubs/#{user.club_id}"
			options = []
			options << menu_link(label: I18n.t("club.single"), url: cluburl)
			options << menu_link(label: I18n.t("player.many"), url: "#{cluburl}/players")
			options << menu_link(label: I18n.t("coach.many"), url: "#{cluburl}/coaches")
			options << menu_link(label: I18n.t("team.many"), url: "#{cluburl}/teams") unless user.is_coach?
			options << menu_link(label: I18n.t("club.rivals"), url: "/clubs")
			options << menu_link(label: I18n.t("location.many"), url: "#{cluburl}/locations")
			options << menu_link(label: I18n.t("slot.many"), url: "#{cluburl}/slots")
			c_menu = menu_drop("manage", label: @clubname, options:)
			return c_menu if user.admin?
			s_menu  = server_menu(user)
			@menu_tabs << menu_drop("admin", label: I18n.t("action.admin"), options: [c_menu, s_menu])
		end
	end

	def player_menu(user)
	end

	# menu to manage server application
	def server_menu(user)
		m_logs  = menu_link(label: I18n.t("server.log"), url: '/home/log', kind: "nav")
		if user.admin?
			options = []
			options << sport_menu
			options << menu_link(label: I18n.t("season.many"), url: '/seasons', kind: "nav")
			options << menu_link(label: I18n.t("club.many"), url: '/clubs', kind: "nav")
			options << menu_link(label: I18n.t("user.many"), url: '/users', kind: "nav")
			options << m_logs
			#options << menu_link(label: I18n.t("action.backup"), url: '/home/log')
			#options << menu_link(label: I18n.t("action.restore"), url: '/home/log')
			menu_drop("server", label: I18n.t("server.single"), options:)
		else
			return m_logs
		end
	end

	# menu to manage sports
	def sport_menu
		options = []
		Sport.all.each do |sport|
			s_path = "/sports/#{sport.id}"
			options << menu_link(label: sport.to_s, url: "#{s_path}")
		end
		menu_drop("sports", label: I18n.t("sport.many"), options:)
	end

	def team_menu(user)
		u_teams = user.team_list
		s_teams = []
		return s_teams if (user.admin? && u_teams.empty?)
		t_url = "/clubs/#{user.club_id}/teams"
		slast = Season.latest
		u_teams.each {|team| s_teams << team if team.season == slast}
		if s_teams.empty?
			m_teams = menu_link(label: I18n.t("team.many"), url: t_url)
		else
			m_teams = menu_drop("teams", label: I18n.t("team.many"))
			s_teams.each {|team| m_teams[:options] << menu_link(label: team.category.to_s, url: "/teams/#{team.id}")}
			m_teams[:options] << menu_link(label: I18n.t("scope.all"), url: t_url)
		end
		[m_teams]
	end

	def user_menu(user)
		@menu_tabs = []
	end
end

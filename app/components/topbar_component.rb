# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
# frozen_string_literal: true

# TopbarComponent - dynamic display of application top bar as ViewComponent
class TopbarComponent < ApplicationComponent
	def initialize(user:, logo:, nick:, home:, logout:)
		@clublogo  = logo
		@clubname  = nick
		@logourl   = { url: "/", data: { turbo_frame: "replace" } }
		@tabcls    = "hover:bg-blue-700 hover:text-white focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200 whitespace-nowrap px-2 py-2 rounded-md font-semibold"
		@srvcls    = "#{@tabcls} inline-flex items-center"
		@lnkcls    = "no-underline block pl-2 pr-2 py-2 hover:bg-blue-700 hover:text-white whitespace-nowrap"
		@logincls  = "login_button rounded hover:bg-blue-700 max-h-8 min-h-6"
		load_menus(user, home, logout)
	end

	def call	# render HTML content
		content_tag(:nav, class: "max-w-7xl mx-auto px-2 sm:px-6 lg:px-8") do
			content_tag(:div, class: "relative flex items-center justify-between h-16") do
				concat(render_large_menu)
				concat(render_ham_menu) if @ham_menu
			end
		end
	end

	private
	# load menu buttons
	def load_menus(user, home, logout)
		@srv_menu = server_menu(user)
		if (@u_logged = user&.present?)
			I18n.locale = (user.locale || I18n.default_locale).to_sym
			@cluburl   = "/clubs/#{user.club_id}"
			@menu_tabs = menu_tabs(user, home, logout)
			@ham_menu  = set_hamburger_menu
		end
	end

	# wrapper to define a dropdown menu hash - :options returned as [] if received as nil
	def menu_drop(name, label: nil, options: [], ham: nil)
		{ kind: :menu, name:, label:, options:, ham:  }
	end

	def menu_link(label:, url:, class: "no-underline block pl-2 pr-2 py-2 hover:bg-blue-700 hover:text-white whitespace-nowrap", kind: :normal)
		case kind
		when :normal
			l_data = { turbo_action: "replace" }
		when :modal
			l_data = { turbo_frame: "modal" }
		when :delete
			l_data = { turbo_method: "delete" }
		end
		{ kind:, label:, url:, class:, data: l_data }
	end

	def menu_tabs(user, home, logout)
		@menu_tabs = []
		if user.admin?
			@menu_tabs << server_menu(user)
			@logourl = { url: "/", data: { turbo_action: "replace" } }
		elsif user.is_manager?
			@menu_tabs += manager_menu
		end
		@menu_tabs << team_menu(user)
		if user.secretary?
			@menu_tabs += secretary_menu
		elsif user.is_coach? && user.coach.active?
			@menu_tabs += coach_menu(user)
		elsif user.is_player? && user.coach.active?
			@menu_tabs << player_menu(user)
		end
		@menu_tabs << user_menu(user, home, logout)
	end

	def render_large_menu
		content_tag(:div, class: "flex-1 flex items-center justify-center sm:items-stretch sm:justify-start", aria_label: "Large menu") do
			concat(render_logo)
			concat(render_tabs) if @menu_tabs
		end
	end

	def render_logo
		content_tag(:div, class: "flex-shrink-0 flex inline-flex items-center font-semibold") do
			link_to(@logourl[:url], class: "inline-flex items-center", data: @logourl[:data]) do
				concat(image_tag(@clublogo, class: "block lg:hidden h-8 w-auto"))
				concat(image_tag(@clublogo, class: "hidden lg:block h-8 w-auto"))
				concat(content_tag(:label, @clubname, class: "ml-1"))
			end
		end
	end

	def render_ham_menu
		content_tag(:div, class: "absolute inset-y-0 right-0 md:hidden flex items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0", aria_label: "Mobile menu") do
			render(@ham_menu)
		end
	end

	def render_tabs
		content_tag(:div, class: "hidden sm:block sm:ml-6 flex space-x-4 text-base text-gray-300", aria_label: "Navigation buttons") do
			@menu_tabs.map do |tab|
				if tab[:options].present?
					render(DropdownComponent.new(tab))
				else
					link_to(tab[:label], tab[:url], class: @tabcls, data: { turbo_frame: "_top", turbo_action: "replace" })
				end
			end.join.html_safe
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
		DropdownComponent.new(menu_drop("hamburger", ham: true, options:))
	end

	# menu buttons for coaches
	def coach_menu(user)
		res = [ menu_link(label: I18n.t("drill.many"), url: "/drills") ]
		res << menu_link(label: I18n.t("player.many"), url: "/clubs/#{user.club_id}/players") unless user.is_manager?
		res
	end

	# menu entry to access logs
	def log_menu
		menu_link(label: I18n.t("server.log"), url: "/home/log")
	end
	# menu buttons for club managers
	def manager_menu
		[
			log_menu
		]
	end

	def player_menu(user)
	end

	# menu buttons for club managers
	def secretary_menu
		[
			menu_link(label: I18n.t("player.many"), url: "#{@cluburl}/players"),
			menu_link(label: I18n.t("coach.many"), url: "#{@cluburl}/coaches"),
			menu_link(label: I18n.t("slot.many"), url: "#{@cluburl}/slots"),
			menu_link(label: I18n.t("location.many"), url: "#{@cluburl}/locations")
		]
	end

	# menu to manage server application
	def server_menu(user)
		options = [
			# menu_link(label: I18n.t("sport.many"), url: "/sports"),
			menu_link(label: I18n.t("club.many"), url: "/clubs"),
			menu_link(label: I18n.t("season.many"), url: "/seasons"),
			menu_link(label: I18n.t("user.many"), url: "/users"),
			log_menu
		]
		menu_drop("server", label: I18n.t("server.single"), options:)
	end

	# Menu for teams visible to the user
	def team_menu(user)
		u_teams = user.team_list
		s_teams = []
		t_url = "/clubs/#{user.club_id}/teams"
		slast = Season.latest
		u_teams.each { |team| s_teams << team if team.season == slast }
		if s_teams.empty?
			m_teams = menu_link(label: I18n.t("team.many"), url: t_url)
		else
			m_teams = menu_drop("teams", label: I18n.t("team.many"))
			s_teams.each { |team| m_teams[:options] << menu_link(label: team.to_s, url: "/teams/#{team.id}") }
			m_teams[:options] << menu_link(label: I18n.t("scope.all"), url: t_url)
		end
		m_teams
	end

	# menu for user-specific options if loogged in
	def user_menu(user, home, logout)
		options  = [
			menu_link(label: I18n.t("user.profile"), url: home),
			menu_link(label: I18n.t("action.logout"), url: logout, kind: :delete)
		]
		menu_drop("profile", label: user.person.nick.presence || user.person.name, options:)
	end
end

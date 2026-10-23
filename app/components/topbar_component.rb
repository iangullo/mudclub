# MudClub - The open source Rails platform to manage amateur sports clubs.
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
# frozen_string_literal: true

# TopbarComponent - dynamic display of application top bar as ViewComponent
class TopbarComponent < ApplicationComponent
	def initialize(user:, club:, home:, logout:, registrations_url: nil)
		if club.is_a?(Club)
			@club    = club
			@cluburl = "/clubs/#{club.id}"
			if user.present? && !user.admin?
				@clublogo = @club.logo
				@clubname = @club.nick
			end
		end

		@clublogo ||= Server.server_logo
		@clubname ||= Server.server_name
		@logourl  = { url: "/", data: { turbo_action: "replace" } }
		@navcls   = "hover:bg-blue-700 hover:text-white focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200 whitespace-nowrap px-2 py-2 rounded-md font-semibold"
		@srvcls   = "#{@navcls} inline-flex items-center"
		@lnkcls   = "no-underline block pl-2 pr-2 py-2 hover:bg-blue-700 hover:text-white whitespace-nowrap"
		@user     = user
		@home     = home
		@logout   = logout
		@regs_url = registrations_url
		@nav_tabs = build_nav_tabs
		@acc_acts = build_account_actions
		@ham_menu = build_hamburger
	end

	def call	# render HTML content
		content_tag(:nav, class: "max-w-7xl mx-auto px-2 sm:px-6 lg:px-8") do
			content_tag(:div, class: "relative flex items-center justify-between h-16") do
				concat(render_large_menu)			# logo + nav_tabs
				concat(render_account_action)	# sign-in OR profile dropdown
				concat(render_ham_menu)	if @ham_menu
			end
		end
	end

	private
		def build_nav_tabs
			tabs = []
			if @user.present?
				tabs += manager_menu        if @user.is_manager?(@club)
				tabs << team_menu(@user)
				tabs += secretary_menu      if @user.is_secretary?(@club)
				tabs += coach_menu(@user)   if @user.is_coach?
				tabs += athlete_menu(@user) if @user.is_athlete?
			end
			tabs << registrations_link    if @regs_url.present?
			tabs.compact
		end

		def build_account_actions
			return sign_in_link if @user.blank?

			menu_drop("profile",
								label:   @user.person.nick.presence || @user.person.name,
								options: [
									menu_link(label: User.fld(:profile),  url: @home),
									menu_link(label: User.act(:sign_out), url: @logout, kind: :delete)
								])
		end

		def build_hamburger
			options = @nav_tabs.map { |tab| hamburger_clone(tab) }.compact
			options << hamburger_clone(@act_menu) if @act_menu
			return nil if options.empty?
			DropdownComponent.new(menu_drop("hamburger", ham: true, options:))
		end

		def hamburger_clone(tab)
			return nil unless tab
			clone = tab.deep_dup
			if clone[:options]
				clone[:sub]     = true
				clone[:name]    = "h_#{clone[:name]}"
				clone[:options] = clone[:options].map { |opt| hamburger_clone(opt) }.compact
			end
			clone
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

		def registrations_link
			return nil if @regs_url.blank?
			menu_link(label: Registration.act(:my_registrations_signed), url: @regs_url)
		end

		def sign_in_link
			menu_link(label: User.act(:sign_in), url: "/users/sign_in", class: @navcls)
		end

		def render_large_menu
			content_tag(:div, class: "flex-1 flex items-center justify-center sm:items-stretch sm:justify-start", aria_label: "Main menu") do
				concat(render_logo)
				concat(render_nav_tabs)
			end
		end

		def render_nav_tabs
			return if @nav_tabs.empty?

			content_tag(:div, class: "hidden sm:block sm:ml-6 flex space-x-4 text-base text-gray-300", aria_label: "Navigation") do
				@nav_tabs.map { |tab|
					if tab[:options].present?
						render(DropdownComponent.new(tab))
					else
						link_to(tab[:label], tab[:url], class: @navcls, data: { turbo_frame: "_top", turbo_action: "replace" })
					end
				}.join.html_safe
			end
		end

		def render_account_action
			return unless @acc_acts

			content_tag(:div, class: "hidden sm:block absolute inset-y-0 right-0 items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0", aria_label: "Account") do
				if @acc_acts[:options].present?
					render(DropdownComponent.new(@acc_acts))
				else
					link_to(@acc_acts[:label], @acc_acts[:url], class: @acc_acts[:class], data: { turbo_frame: "_top", turbo_action: "replace" })
				end
			end
		end

		def render_ham_menu
			content_tag(:div, class: "absolute inset-y-0 right-0 md:hidden flex items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0", aria_label: "Mobile menu") do
				render(@ham_menu)
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

		def athlete_menu(user)
			[]
		end

		# menu buttons for coaches
		def coach_menu(user)
			[ menu_link(label: Drill.label(:plural), url: "/drills") ]
		end

		# menu entry to access logs
		def log_menu
			menu_link(label: Server.fld(:log), url: "/server/log")
		end

		# menu buttons for club managers
		def manager_menu
			return [] unless @cluburl

			menu = @user.admin? ?
				menu_link(label: Club.label, url: @cluburl) :
				log_menu

			[ menu ]
		end

		# menu buttons for club managers
		def secretary_menu
			[
				menu_link(label: Membership.kind_label(:athlete, :plural), url: "#{@cluburl}/memberships?kind=athlete"),
				menu_link(label: Membership.kind_label(:coach, :plural), url: "#{@cluburl}/memberships?kind=coach"),
				menu_link(label: Slot.label(:plural), url: "#{@cluburl}/slots"),
				menu_link(label: Location.label(:plural), url: "#{@cluburl}/locations")
			]
		end

		# menu to manage server application
		def server_menu
=begin
			options = [
				menu_link(label: Sport.label(:plural), url: "/sports"),
				menu_link(label: Club.label(:plural), url: "/clubs"),
				menu_link(label: Season.label(:plural), url: "/seasons"),
				menu_link(label: User.label(:plural), url: "/users"),
				log_menu
			]
			menu_drop("server", label: I18n.t("server.single"), options:)
=end
			menu_link(label: Server.label, url: "/server")
		end

		# Menu for teams visible to the user
		def team_menu(user)
			u_teams = user.teams
			s_teams = []
			t_url = "/clubs/#{user.club_id}/teams" if user.club_id
			slast = Season.latest
			u_teams.each { |team| s_teams << team if team.season == slast }
			if s_teams.empty? && t_url
				m_teams = menu_link(label: Team.label(:plural), url: t_url)
			else
				m_teams = menu_drop("teams", label: Team.label(:plural))
				s_teams.each { |team| m_teams[:options] << menu_link(label: team.to_s, url: "#{t_url}/#{team.id}") }
				m_teams[:options] << menu_link(label: I18n.t("scope.all"), url: t_url) if t_url
			end
			m_teams
		end
end

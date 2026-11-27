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
	#-------------------------------------
	# CSS definitions
	#-------------------------------------
	# Shared hover feedback — every interactive element in the bar uses the same color
	CTRL_HOVER = %w[hover:bg-blue-700 hover:text-white].freeze

	# Desktop nav tabs and standalone links (sign-in)
	NAV_LAYOUT = %w[
		inline-flex items-center whitespace-nowrap rounded-md font-semibold
		focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200
		px-2 py-2
	].freeze
	NAV_CLS = (NAV_LAYOUT + CTRL_HOVER).freeze

	# Anchor rendered by `menu_link` when the hash is NOT consumed by a
	# DropdownComponent (currently only the default class argument).
	LNK_LAYOUT = %w[block pl-2 pr-2 py-2 no-underline whitespace-nowrap].freeze
	LNK_CLS = (LNK_LAYOUT + CTRL_HOVER).freeze

	# Containers
	IMG_SIZE     = %w[h-8 w-auto].freeze
	SHOW_IMG_CLS = (%w[block lg:hidden] + IMG_SIZE).freeze
	HIDE_IMG_CLS = (%w[hidden lg:block] + IMG_SIZE).freeze
	LOGO_CLS     = %w[flex-shrink-0 flex inline-flex items-center font-semibold].freeze
	BAR_CLS      = %w[max-w-7xl mx-auto px-2 sm:px-6 lg:px-8].freeze
	MAIN_CLS     = %w[flex-1 flex items-center justify-center sm:items-stretch sm:justify-start].freeze
	OBJ_CLS      = %w[relative flex items-center justify-between h-14].freeze
	TAB_CLS      = %w[hidden md:block sm:ml-6 flex space-x-4 text-gray-300].freeze
	HAM_CLS      = %w[absolute inset-y-0 right-0 md:hidden flex items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0].freeze
	USR_CLS      = %w[hidden md:block absolute inset-y-0 right-0 items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0].freeze

	#-------------------------------------
	# Component standard methods
	#-------------------------------------

	def initialize(user:, club:, home:, logout:, clubs: [], registrations_url: nil)
		@user          = user
		@explicit_club = club
		@club          = club.is_a?(Club) ? club : nil
		@clubs         = Array(clubs)
		@home          = home
		@logout        = logout
		@regs_url      = registrations_url

		if @club.present?
			@brand_logo = @club.logo
			@brand_name = @club.nick
		else
			@brand_logo = Server.server_logo
			@brand_name = Server.server_name
		end
	end

	def before_render
		# Re-sync with controller's @club in case a controller before_action loaded @club after set_application_context
		ctrl_club = controller.instance_variable_get(:@club)
		resolved  = ctrl_club.is_a?(Club) ? ctrl_club : @explicit_club
		@club     = resolved.is_a?(Club) ? resolved : nil

		if @club.present?
			@brand_logo = @club.logo
			@brand_name = @club.nick
			@brand_url  = club_path(@club)
		else
			@brand_logo = Server.server_logo
			@brand_name = Server.server_name
			@brand_url  = root_path(club_id: :none)
		end

		@brand_menu = build_brand_switcher
		@nav_tabs   = build_nav_tabs
		@acc_acts   = build_account_actions
		@ham_menu   = build_hamburger
	end

	def call	# render HTML content
		content_tag(:nav, class: BAR_CLS) do
			content_tag(:div, class: OBJ_CLS) do
				concat(render_large_menu)			# logo + nav_tabs
				concat(render_account_action)	# sign-in OR profile dropdown
				concat(render_ham_menu)	if @ham_menu
			end
		end
	end

	#-------------------------------------
	# Component internal support methods
	#-------------------------------------

	private
		# ------------------------------------------------------------------
		# 1. Left Brand / Multi-Club Switcher
		# ------------------------------------------------------------------
		def show_brand_switcher?
			return false if @user.blank?
			return @clubs.any? if @user.admin?

			@clubs.size > 1
		end

		def build_brand_switcher
			return nil unless show_brand_switcher?

			options = []

			# Server root entry for system admins (only when currently inside a club)
			if @user.admin? && @club.present?
				options << menu_link(
					label: Server.server_name,
					url:   root_path(club_id: :none),
					icon:  Server.server_logo
				)
			end

			# All active clubs except the currently selected one
			@clubs.each do |c|
				next if @club&.id == c.id

				options << menu_link(
					label: c.nick,
					url:   club_path(c),
					icon:  c.logo
				)
			end

			return nil if options.empty?

			menu_drop(
				"context_switcher",
				label:   @brand_name,
				icon:    @brand_logo,
				options: options,
				align:   :left
			)
		end

		def render_logo
			content_tag(:div, class: LOGO_CLS) do
				if @brand_menu
					render(DropdownComponent.new(@brand_menu))
				else
					link_to(@brand_url, class: "inline-flex items-center gap-2 rounded-md px-2 py-1 hover:bg-blue-800", data: { turbo_action: :replace }) do
						concat(image_tag(@brand_logo, class: IMG_SIZE))
						concat(content_tag(:span, @brand_name, class: "truncate max-w-[10rem] sm:max-w-xs"))
					end
				end
			end
		end

		# ------------------------------------------------------------------
		# 2. Center Context-Scoped Navigation Tabs
		# ------------------------------------------------------------------
		def build_nav_tabs
			tabs = []

			if @user.present?
				effective_club = @club || (@clubs.first if @user.admin? && @clubs.one?)

				if effective_club.present?
					tabs << club_management_menu(effective_club)
					tabs << team_menu(@user, effective_club)
				else
					tabs << multi_club_teams_menu(@user)
				end

				tabs << coach_menu if @user.is_coach?
			elsif @regs_url.present?
				tabs << registrations_link
			end

			tabs.compact
		end

		def club_management_menu(club = @club)
			return nil unless club

			options = []

			if allowed_for_club?(MembershipPolicy, :index?, nil, club)
				options << menu_link(label: Membership.kind_label(:athlete, :plural), url: club_members_path(club, kind: :athlete), symbol: :athlete)
				options << menu_link(label: Membership.kind_label(:coach, :plural),   url: club_members_path(club, kind: :coach),   symbol: :coach)
			end

			if allowed_for_club?(RegistrationPolicy, :index?, nil, club)
				options << menu_link(label: Registration.label(:plural), url: club_registrations_path(club), symbol: :registration)
			end

			if allowed_for_club?(SlotPolicy, :index?, nil, club)
				options << menu_link(label: Slot.label(:plural), url: club_slots_path(club), symbol: :timetable)
			end

			if allowed_for_club?(LocationPolicy, :index?, nil, club)
				options << menu_link(label: Location.label(:plural), url: club_locations_path(club), symbol: :location)
			end

			if allowed_for_club?(EventPolicy, :index?, nil, club)
				options << menu_link(label: Calendar.label, url: club_events_path(club), symbol: :calendar)
			end

			if allowed_for_club?(ClubPolicy, :log?, club, club)
				options << menu_link(label: Server.fld(:log), url: log_club_path(club), symbol: :actions)
			end

			return nil if options.empty?

			menu_drop("club_mgmt", label: Club.label, options:)
		end

		def team_menu(user, club = @club)
			return nil if user.blank? || club.blank?

			teams = user.teams.select { |t| t.club_id == club.id && t.season == Season.latest }
			return nil if teams.empty? && !@user.is_secretary?(club) && !@user.is_manager?(club)

			options = teams.map { |t| team_menu_link(t) }
			options << all_teams_link(club)

			menu_drop("teams", label: Team.label(:plural), options: options)
		end

		def multi_club_teams_menu(user)
			my_teams = user.teams.select { |t| t.season == Season.latest }
			grouped  = my_teams.group_by(&:club)
			return nil if grouped.empty?

			if grouped.size == 1
				club, teams = grouped.first
				options = teams.map { |t| team_menu_link(t) } << all_teams_link(club)
				menu_drop("teams", label: Team.label(:plural), options: options)
			else
				menu_drop("teams", label: Team.label(:plural), options: grouped.map do |club, teams|
					options = teams.map { |t| team_menu_link(t) } << all_teams_link(club)
					menu_drop("teams_club_#{club.id}", label: club.nick, options: options)
				end)
			end
		end

		def coach_menu
			menu_link(label: Drill.label(:plural), url: drills_path)
		end

		def server_menu
			menu_link(label: Server.label, url: server_path)
		end

		# ------------------------------------------------------------------
		# 3. Right Account & Personal Actions
		# ------------------------------------------------------------------
		def build_account_actions
			return sign_in_link if @user.blank?

			options = [
				menu_link(label: User.fld(:profile), url: @home)
			]
			options << registrations_link if @regs_url.present?
			options << menu_link(label: User.act(:sign_out), url: @logout, kind: :delete)

			menu_drop(
				"profile",
				label:   @user.person&.nick.presence || @user.person&.name || @user.email,
				align:   :right,
				options:,
				**profile_avatar_attrs
			)
		end

		def profile_avatar_attrs
			pic = @user.picture
			if pic.is_a?(Hash) && pic[:symbol]
				{ symbol: { concept: pic[:symbol], options: { css: "text-gray-200" } } }
			else
				{ icon: pic, i_class: "h-6 w-6 rounded-full object-cover" }
			end
		end

		# ------------------------------------------------------------------
		# 4. Mobile Hamburger Drawer
		# ------------------------------------------------------------------
		def build_hamburger
			options = []
			options.concat(@nav_tabs.map { |tab| hamburger_clone(tab) }.compact)
			options << hamburger_clone(@acc_acts) if @acc_acts
			return nil if options.empty?

			DropdownComponent.new(menu_drop("hamburger", ham: true, options:, align: :right))
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

		# ------------------------------------------------------------------
		# Helpers & Renderers
		# ------------------------------------------------------------------
		def menu_drop(name, label: nil, options: [], ham: nil, align: nil, icon: nil, symbol: nil, i_class: nil)
			{ kind: :menu, name:, label:, options:, ham:, align:, icon:, symbol:, i_class: }.compact
		end

		def menu_link(label:, url:, class: LNK_CLS, kind: :normal, icon: nil, symbol: nil)
			l_data = case kind
			when :normal then { turbo_frame: "_top", turbo_action: :replace }
			when :modal  then { turbo_frame: :modal }
			when :delete then { turbo_method: :delete }
			end

			resolved_symbol =
				if symbol.is_a?(Hash)
					symbol
				elsif symbol.present?
					{ concept: symbol, options: { css: "min-h-6 min-w-6 bg-white rounded p-0.5 mr-1 ml-1" } }
				end
			{ kind:, label:, url:, class:, data: l_data, icon:, symbol: resolved_symbol }.compact
		end

		def registrations_link
			return nil if @regs_url.blank?
			menu_link(label: Registration.act(:my_registrations_signed), url: @regs_url)
		end

		def sign_in_link
			menu_link(label: User.act(:sign_in), url: new_user_session_path, class: NAV_CLS, symbol: :login)
		end

		def team_menu_link(team)
			menu_link(label: team.to_s, url: club_team_path(team.club_id, team.id))
		end

		def all_teams_link(club)
			menu_link(label: UI::Selection.val(:all, gender: :neutral), url: club_teams_path(club.id))
		end

		def render_large_menu
			content_tag(:div, class: MAIN_CLS, aria: { label: "Main menu" }) do
				concat(render_logo)
				concat(render_nav_tabs)
			end
		end

		def render_nav_tabs
			return if @nav_tabs.empty?

			content_tag(:div, class: TAB_CLS, aria: { label: "Navigation" }) do
				safe_join(@nav_tabs.map do |tab|
					if tab[:options].present?
						render(DropdownComponent.new(tab))
					else
						link_to(tab[:label], tab[:url], class: NAV_CLS, data: tab[:data])
					end
				end)
			end
		end

		def render_account_action
			return unless @acc_acts

			content_tag(:div, class: USR_CLS, aria: { label: "Account" }) do
				if @acc_acts[:options].present?
					render(DropdownComponent.new(@acc_acts))
				else
					link_to(@acc_acts[:label], @acc_acts[:url], class: @acc_acts[:class], data: @acc_acts[:data])
				end
			end
		end

		def render_ham_menu
			content_tag(:div, class: HAM_CLS, aria: { label: "Mobile menu" }) do
				render(@ham_menu)
			end
		end

		private
			def allowed_for_club?(policy_class, action, record = nil, club = @club)
				return false unless defined?(policy_class) && policy_class.method_defined?(action)

				policy_class.new(@user, record:, club:).public_send(action)
			end
end

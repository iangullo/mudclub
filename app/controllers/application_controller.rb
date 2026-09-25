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
# Core shared controller methods
class ApplicationController < ActionController::Base
	include RoutingHelper

	# Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
	allow_browser versions: :modern
	before_action :set_application_context
	around_action :switch_locale

	# simplify calls to routing definitions
	helper RoutingHelper

	# Make these methods available to views and helpers
	helper_method :u_admin?, :u_club, :u_manager?, :u_person,
								:user_in_club?,	:date_string

	# auxliary check for params that need matching values
	def assert_param_matches!(param_name, value)
		param = params[param_name]
		return if param.blank?
		return if value&.id&.to_s == param.to_s

		raise ActiveRecord::RecordNotFound
	end

	# NEW authorization policy management approach.
	def check_policy!(policy_class, record: nil, **context)
		context[:club] ||= @club
		policy = policy_class.new(current_user, record:, **context)
		method = "#{action_name}?"

		unless policy.respond_to?(method)
			raise NotImplementedError, "#{policy_class}##{method} not implemented"
		end

		deny_access unless policy.public_send(method)
		policy
	end

	# return a ButtonComponent object from a definition hash
	def create_button(button)
		button ? ButtonComponent.new(**button) : nil
	end

	# return FieldsComponent object from a fields array
	def create_fields(fields)
		fields ? FieldsComponent.new(fields) : nil
	end
	# return TableComponent object from a table hash
	def create_table(table, align: nil)
		table ? TableComponent.new(table, align:) : nil
	end

	# prepare typical controller index page variables
	def create_index(title:, fields: nil, table: nil, page: nil, retlnk: nil, submit: nil)
		@title  = create_fields(title)
		@fields = create_fields(fields)
		@table  = create_table(table)
		@page   = page
		if retlnk || submit
			@submit = create_submit(close: :back, retlnk:, submit:)
		else
			@submit = create_submit(close: :close, submit: nil)
		end
	end

	# Create a submit component
	def create_submit(close: :close, submit: :save, retlnk: nil, frame: nil)
		SubmitComponent.new(close:, submit:, retlnk:, frame:)
	end

	# Where the user came from, for a "Back" link.
	# Only trusts same-origin referers; falls back to `default` otherwise.
	def back_link(default: root_path)
		case @rdx&.to_i
		when 0, nil	# return to default, typically provided by controller
			default
		when 1	# return to users home_path
			path_for(current_user)
		when 2	# return to log_path
			home_log_path
		when 3
			return path_for(Membership.find(params[:member_id])) unless params[:member_id].blank?
			return path_for(User.find(params[:user_id])) unless params[:user_id].blank?
			default
		else
			default
		end
	end

	# ensure @season matches the calling context.
	# :obj is an object that has a :season_id link
	def get_season(obj: nil)
		unless @season&.id != obj&.season_id&.to_i
			@season = Season.search(obj&.season_id)
		end
		@season
	end

	# check if a string is an integer
	def is_integer(cad)
		cad.to_i.to_s == cad
	end

	# parse a value to determine if its true
	def to_boolean(value)
		val = value.presence
		(val&.to_s == "true" || val.to_i == 1)
	end

	# standard message for actions that had no data to change
	def no_data_notice(trail: nil)
		cad = I18n.t("status.no_data")
		cad = "#{cad} (#{trail})" if trail
		helpers.flash_message(cad, "info")
	end

	# wrappers to manage navigation routing specifiers
	# rdx (radix) arguemnt specifies base url for this view
	#		nil=>toplevel
	#		0: club/season view)
	#		1: user home view
	#		2: server logs view
	def p_rdx(base = params[:controller])
		get_param(base, :rdx)
	end

	def p_log(base = params[:controller])
		get_param(base, :log)
	end

	def p_clubid(base = params[:controller])
		get_param(base, :club_id, objid: true)
	end

	def p_seasonid(base = params[:controller])
		get_param(base, :season_id, objid: true)
	end

	def p_teamid(base = params[:controller])
		get_param(base, :team_id, objid: true)
	end

	def p_userid(base = params[:controller])
		get_param(base, :user_id, objid: true)
	end

	# check if some specific params are passed
	def param_passed(*keys)
		current_hash = params
		keys.each do |key|
			return nil unless current_hash[key].present?
			current_hash = current_hash[key]
		end
		current_hash
	end

	# register a new user action
	def register_action(kind, description, url: nil, modal: nil)
		u_act = UserAction.new(user_id: current_user.id, kind:, description:, url:, modal:)
		current_user.user_actions << u_act
		u_act.save
	end

	# set the action's context
	def set_application_context
		if user_signed_in?
			@club   = u_club
			@rdx    = p_rdx
			@season = Season.search(p_seasonid)
		end
		@favicon  = user_favicon(@club)
		@topbar   =
			TopbarComponent.new(
				user: current_user,
				club: @club,
				home: u_path,
				logout: destroy_user_session_path
			)
	end

	def load_participation_context
		@team   = @club.teams.find(params[:team_id]) if params[:team_id].present?
		s_kind  = @kind || "participation"
		@status = params[:status].presence ||
							session.dig("#{s_kind}_filters", "status")
		@search = params[:search].presence ||
							session.dig("#{s_kind}_filters", "search")
	end

	# switch app locale
	def switch_locale(&action)
		locale   = (params[:locale] || current_user&.locale || I18n.default_locale)
		I18n.with_locale(locale, &action)
	end

	# Standard string format for date values
	def date_string(date)
		case date
		when Date, Time, DateTime
			date&.strftime("%d/%m/%Y")
		else
			""
		end
	end

	def u_admin?
		current_user&.admin?
	end

	def u_manager?
		current_user&.is_manager?(@club)
	end

	def u_club
		return nil unless current_user
		clubs = current_user.clubs
		return clubs.first if clubs.size == 1
		return @club if user_in_club?
		nil
	end

	def u_person
		current_user&.person
	end

	# wrapper to manage return links home path
	def u_path
		user_signed_in? ? user_path(current_user, rdx: 1) : "/"
	end

	# Check whether the user's club is the same as @club
	def user_in_club?(club = @club)
		return false unless club.is_a?(Club)
		current_user.member_of?(club)
	end

	# check if a string is a valid date
	def valid_date(v_string)
		return nil if (d_str = v_string&.last(10))&.length != 10
		d_hash = Date._parse(d_str)
		return nil if d_hash&.size !=3
		v_date = Date.valid_date?(d_hash[:year].to_i, d_hash[:month].to_i, d_hash[:month].to_i)
		v_date ? d_str : nil
	end

	private

		def deny_access(message = I18n.t("shared.messages.access_denied"))
			respond_to do |format|
				format.html do
					redirect_back(
						fallback_location: "/",
						alert: message,
						status: :see_other
					)
				end

				format.turbo_stream do
					redirect_back(
						fallback_location: "/",
						alert: message,
						status: :see_other
					)
				end

				format.json do
					render json: { error: message }, status: :forbidden
				end
			end
		end

		# get a param either from base or from a sub-node
		def get_param(base = params[:controller], key, objid: false)
			res = (param_passed(key) || param_passed(base, key) || param_passed(base.singularize, key))
			return res unless objid
			res.nil? ? nil :  res.to_i
		end

		# Calculate pagination parameters based on available screen space or other criteria
		def paginate(data, lines = 1)
			drows = case helpers.device
				when "desktop", "tablet"; 18 # rubocop:disable Layout/CaseIndentation
				when "mobile"; 15 # rubocop:disable Layout/CaseIndentation
				else; 25
			end
			per_page = (drows/lines).round
			current_page = params[:page] || 1

			data.page(current_page).per(per_page)
		end

		# determine the app favicon based on user favicon
		def user_favicon(club)
			if club&.avatar&.attached?
				url_for(club.avatar)
			else
				"mudclub.svg"
			end
		end
end

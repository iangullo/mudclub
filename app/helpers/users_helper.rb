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
module UsersHelper
	# return icon and top of HeaderComponent
	def user_title_fields(title, icon: "user.svg", rows: 2, cols: nil, size: nil, _class: nil)
		title_start(icon: icon, title: title, rows: rows, cols: cols, size: size, _class: _class)
	end

	# return grid for @users GridComponent
	def user_grid
		title = [
			{kind: "normal", value: I18n.t("person.name")},
			{kind: "normal", value: I18n.t("role.player_a"), align: "center"},
			{kind: "normal", value: I18n.t("role.coach_a"), align: "center"},
			{kind: "normal", value: I18n.t("role.admin_a"), align: "center"},
			{kind: "normal", value: I18n.t("user.last_in"), align: "center"}
		]
		title << button_field({kind: "add", url: new_user_path, frame: "modal"}) if u_admin? or u_coach?

		rows = Array.new
		@users.each { |user|
			row = {url: user_path(user), items: []}
			row[:items] << {kind: "normal", value: user.s_name}
			row[:items] << {kind: "icon", value: user.is_player? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << {kind: "icon", value: user.is_coach? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << {kind: "icon", value: user.admin? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << {kind: "normal", value: user.last_sign_in_at&.to_date, align: "center"}
			row[:items] << button_field({kind: "delete", url: row[:url], name: user.s_name}) if u_admin? and user.id!=current_user.id
			rows << row
		}
		{title: title, rows: rows}
	end

	# fields to show when looking a user profile
	def user_show_fields
		res = user_title_fields(@user.person.s_name, icon: @user.picture, _class: "rounded-full", cols: 4)
		if current_user == @user	# only allow current user to change his own password
			res.last << {kind: "gap"}
			res.last <<	button_field(
				{kind: "link", icon: "key.svg", label: I18n.t("action.change"), url: edit_user_registration_path, frame: "modal", d_class: "inline-flex align-middle m-1 text-sm", flip: true},
				rows: 2,
				align: "right"
			)
		end
		res << [{kind: "label", value: @user.person.surname, cols: 4}]
		res
	end

	# Fieldcomponents to display user roles
	def user_role
		res =[[
			{kind: "icon", value: "logout.svg", tip: I18n.t("user.last_in"), tipid: "last"},
			{kind: "string", value: @user.last_login, cols: 3},
			{kind: "gap"},
			{kind: "contact", email: @user.person.email, phone: @user.person.phone, device: device}
		]]
		#res << [		# removing cause IP registered is always local - from NGINX
		#	{kind: "gap", size: 1},
		#	{kind: "string", value: "(#{@user.last_from})",cols: 3}
		#] if @user.last_sign_in_ip?
		res << [{kind: "label", value: "#{I18n.t("user.profile")}: "}]
		res.last << {kind: "icon", value: "key.svg", tip: I18n.t("role.admin"), tipid: "adm"} if @user.admin?
		res.last << {kind: "icon", value: "coach.svg", tip: I18n.t("role.coach"), tipid: "coach"} if @user.is_coach?
		res.last << {kind: "icon", value: "player.svg", tip: I18n.t("role.player"), tipid: "play"} if @user.is_player?
		res.last << {kind: "gap"}
		unless @user.user_actions.empty?
			res.last << button_field(
				{kind: "link", icon: user_actions_icon, url: actions_user_path, label: I18n.t("user.actions"), frame: "modal", flip: true},
				cols: 2,
				align: "right"
			)
		end
		res
	end

	# return FieldComponents for form title
	def user_form_title(title:)
		res = user_title_fields(title, icon: @user.picture, rows: 4, cols: 2, size: "100x100", _class: "rounded-full")
		res << [
			{kind: "label", value: I18n.t("person.name_a")},
			{kind: "text-box", key: :name, value: @user.person.name, placeholder: I18n.t("person.name")}
		]
		res << [
			{kind: "label", value: I18n.t("person.surname_a")},
			{kind: "text-box", key: :surname, value: @user.person.surname, placeholder: I18n.t("person.surname")}
		]
		res << [
			{kind: "icon", value: "calendar.svg"},
			{kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @user.person.birthday}
		]
		res
	end

	# return FieldComponents for form user role
	def user_form_role
		res = [[{kind: "label", value: "#{I18n.t("user.profile")}:"}]]
		if u_admin?
			res.last << {kind: "select-box", align: "center", key: :role, options: User.role_list, value: @user.role}
		else
			res.last << {kind: "string", align: "center", value: I18n.t("role.#{@user.role}")}
		end
		res.last << {kind: "gap"}
		res.last << {kind: "label", value: "#{I18n.t("locale.lang")}:"}
		res.last << {kind: "select-box", align: "center", key: :locale, options: User.locale_list, value: @user.locale}
		res
	end

	# return FieldComponents for form user avatar
	def user_form_avatar
		[[{kind: "upload", key: :avatar, label: I18n.t("person.pic"), value: @user.avatar.filename}]]
	end

	# return FieldComponents for form user personal data
	def user_form_person
		[
			[
				{kind: "label", value: I18n.t("person.pid_a"), align: "right"},
				{kind: "text-box", key: :dni, size: 8, value: @user.person.dni, placeholder: I18n.t("person.pid")},
				{kind: "gap"}, {kind: "icon", value: "at.svg"},
				{kind: "email-box", key: :email, value: @user.person.email, placeholder: I18n.t("person.email")}
			],
			[
				{kind: "icon", value: "user.svg"},
				{kind: "text-box", key: :nick, size: 8, value: @user.person.nick, placeholder: I18n.t("person.nick")},
				{kind: "gap"}, {kind: "icon", value: "phone.svg"},
				{kind: "text-box", key: :phone, size: 12, value: @user.person.phone, placeholder: I18n.t("person.phone")}
			]
		]
	end

	# return FieldComponents for form user personal data
	def user_form_pass
		[
			[
				{kind: "icon", value: "key.svg"},
				{kind: "password-box", key: :password, placeholder: I18n.t("password.single")}
			],
			[
				{kind: "icon", value: "key.svg"},
				{kind: "password-box", key: :password_confirmation, placeholder: I18n.t("password.confirm")}
			],
			[
				{kind: "gap"},
				{kind: "text", value: I18n.t("password.confirm_label"), cols: 2, class: "text-xs"}
			]
		]
	end

	# return user_actions GridComponent
	def user_actions_title
		res  = user_title_fields(@user.person.s_name, icon: user_actions_icon)
		res << [{kind: "subtitle", value: I18n.t("user.actions")}]
	end

	# return user_actions GridComponent
	def user_actions_table
		res = [[
			{kind: "top-cell", value: I18n.t("calendar.date"), align: "center"},
			{kind: "top-cell", value: I18n.t("drill.desc"), align: "center"}
		]]
		@user.user_actions.each { |u_act|
			res << [
				{kind: "string", value: u_act.date_time, class: "border px py"},
				{kind: "string", value: u_act.description, class: "border px py"}
			]
		}
		res
	end

	# prepare clear button only if there are actions to clear
	def user_actions_clear_fields
		return nil if @user.user_actions.empty?
		return {kind: "clear", url: clear_actions_user_path, name: @user.s_name}
	end

	private
		# tails actions_icon to mark if log is quite full
		def user_actions_icon
			@user.user_actions.count>10 ? "user_actions_full.svg" : "user_actions.svg"
		end
end

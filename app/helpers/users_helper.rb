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
module UsersHelper
	# fields to show when looking a user profile
	def user_show_fields
		res       = person_show_fields(@user.person, title: I18n.t("user.single"), icon: @user.picture, rows: 3)
		res[3][0] = obj_status_field(@user)
		if current_user == @user	# only allow current user to change his own password
			res[3] <<	button_field(
				{kind: :link, icon: "key.svg", label: I18n.t("action.change"), url: edit_user_registration_path(rdx: @rdx), frame: "modal", d_class: "inline-flex align-middle m-1 text-sm", flip: true},
				align: "right",
				rows: 2
			)
		end
		res
	end

	# Fieldcomponents to display user roles
	def user_role_fields(user=current_user, grid: false)
		res =[]
		#res << [		# removing cause IP registered is always local - from NGINX
		#	gap_field(size: 1},
		#	{kind: :string, value: "(#{@user.last_from})",cols: 3}
		#] if @user.last_sign_in_ip?
		if user.admin?
			res << icon_field("key.svg", tip: I18n.t("role.admin"), tipid: "adm")
		elsif user.manager?
			res << icon_field("mudclub.svg", tip: I18n.t("role.manager"), tipid: "mng")
		else
			res << gap_field(size: 0)
		end
		res << (user.is_coach? ? icon_field("coach.svg", tip: I18n.t("role.coach"), tipid: "coach") : gap_field(size: 0))
		res << (user.is_player? ? icon_field("player.svg", tip: I18n.t("role.player"), tipid: "play") : gap_field(size: 0))
		return res if grid	# only interested in these 3 icons
		res << gap_field
		unless @user.user_actions.empty?
			res <<	button_field(
				{kind: :link, icon: user_actions_icon, url: actions_user_path, label: I18n.t("user.actions"), frame: "modal"},
			)
		end
		[res]
	end

	# return FieldComponents for form user role
	def user_form_role
		if u_admin?
			res = [
				obj_club_selector(@user),
				[
					icon_field("key.svg", tip: I18n.t("user.profile"), tipid: "urole"),
					{kind: :select_box, align: "left", key: :role, options: User.role_list, value: @user.role}
				]
			]
		else
			res = [
				[
					icon_field(@user.club&.logo || "mudclub.svg", tip: @user.club&.nick || I18n.t("club.none"), tipid: "uclub"),
					{kind: :string, align: "center", value: I18n.t("role.#{@user.role}")},
					{kind: :hidden, key: :club_id, value: @user.club_id}
				]
			]
		end
		res.last <<	gap_field
		res.last << icon_field("locale.png", tip: I18n.t("locale.lang"), tipid: "lang")
		res.last << {kind: :select_box, align: "center", key: :locale, options: User.locale_list, value: @user.locale}
		res.last << {kind: :hidden, key: :rdx, value: @rdx} if @rdx
		res
	end

	# return FieldComponents for form user personal data
	def user_form_pass
		[
			[
				icon_field("key.svg"),
				{kind: :password_box, key: :password, placeholder: I18n.t("password.single"), mandatory: {length: 8}}
			],
			[
				icon_field("key.svg"),
				{kind: :password_box, key: :password_confirmation, placeholder: I18n.t("password.confirm"), mandatory: {length: 8}}
			],
			[
				gap_field,
				{kind: :text, value: I18n.t("password.confirm_label"), cols: 2, class: "text-xs"}
			]
		]
	end

	# return user_actions GridComponent
	def user_actions_title
		res  = person_title_fields(title: @user.person.s_name, icon: user_actions_icon, rows: 4)
		res << [{kind: :subtitle, value: I18n.t("user.actions")}]
	end

	# return user_actions GridComponent
	def user_actions_table
		res = [[
			{kind: :top_cell, value: I18n.t("calendar.date"), align: "center"},
			{kind: :top_cell, value: I18n.t("drill.desc"), align: "center"}
		]]
		@user.user_actions.order(updated_at: :desc).each { |u_act|
			res << [
				{kind: :string, value: u_act.date_time, class: "border px py"},
				{kind: :string, value: u_act.description, class: "border px py"}
			]
		}
		res
	end

	# prepare clear button only if there are actions to clear
	def user_actions_clear_fields
		return nil if @user.user_actions.empty?
		return {kind: :clear, url: clear_actions_user_path(rdx: @rdx), name: @user.s_name}
	end

	# return grid for @users GridComponent
	def user_grid(users: @users)
		title = [
			{kind: :normal, value: I18n.t("club.single")},
			{kind: :normal, value: I18n.t("person.name")},
			{kind: :normal, value: I18n.t("user.profile"), align: "center", cols: 3},
			{kind: :normal, value: I18n.t("person.contact"), align: "center"},
			{kind: :normal, value: I18n.t("user.last_in"), align: "center"}
		]
		title << button_field({kind: :add, url: new_user_path(rdx: @rdx), frame: "modal"}) if u_admin?

		rows = Array.new
		@users.each { |user|
			row = {url: user_path(user, rdx: @rdx), items: []}
			row[:items] << icon_field((user.active? ? user.club.logo : "No.svg"))
			row[:items] << {kind: :normal, value: user.s_name}
			row[:items] += user_role_fields(user, grid: true)
			row[:items] << {kind: :contact, phone: user.person.phone, email: user.person.email}
			row[:items] << {kind: :normal, value: user.last_sign_in_at&.to_date, align: "center"}
			row[:items] << button_field({kind: :delete, url: row[:url], name: user.s_name}) if u_admin? and user.id!=current_user.id
			rows << row
		}
		{title:, rows:}
	end

	private
		# tails actions_icon to mark if log is quite full
		def user_actions_icon
			@user.user_actions.count>10 ? "user_actions_full.svg" : "user_actions.svg"
		end
end

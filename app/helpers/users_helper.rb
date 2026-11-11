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
module UsersHelper
	# fields to show when looking a user profile
	def user_show
		res = person_show_title(@user)
		res.pop
		res[3][1] = user_roles(@user)
		unless @user.user_actions.empty?
			res.last << normal_button(
				{ kind: :link, symbol: user_actions_symbol, url: actions_user_path, label: UserAction.label(:short), frame: :modal }
			)
		end
		if current_user == @user	# only allow current user to change his own password
			res[2] <<	normal_button(
				{ kind: :link, symbol: :key, label: I18n.t("action.change"), url: edit_user_registration_path(rdx: @rdx), frame: :modal, d_class: "inline-flex align-middle m-1 text-sm", flip: true },
				align: "right"
			)
		end
		res
	end

	# Fieldcomponents to display user roles
	def user_roles(user = current_user, table: false)
		roles =[]

		roles << symbol_item("website", { title: I18n.t("role.admin") }) if user.admin?
		roles << symbol_item(:board_member, { title: Membership.kind_label(:board_member) }) if user.is_board_member?
		roles << symbol_item(:coach, { namespace: "sport", title: Sport.term(:coach) }) if user.is_coach?
		roles << symbol_item(:athlete, { namespace: "sport", title: Sport.term(:athlete) }) if user.is_athlete?
		res = { kind: :roles, symbols: roles, align: :center }
		if table	# only interested in these 3 icons
			res[:class] = "border"
			return [ res ]
		end
		res[:align] = :left
		res
	end

	#----------------------------------------------
	# Field definitions for person forms
	#----------------------------------------------
	def user_form_title(user: @user, icon: user&.picture, title:, cols: 2)
		person  = user.person
		l_name  = Person.fld(:name)
		l_surn  = Person.fld(:surname)
		l_nick  = Person.fld(:nickname)
		l_email = Person.fld(:email)
		m_email = { length: 7 }

		res = person_title(title:, icon:, rows: 3, cols:, form: true)
		res += [
			[
				{ kind: :text_box, key: :name, value: person&.name, placeholder: l_name, cols: 2, mandatory: { length: 2 } }
			],
			[
				{ kind: :text_box, key: :surname, value: person&.surname, placeholder: l_surn, cols: 2, mandatory: { length: 2 } }
			],
			[
				symbol_item(:email, { type: :button, title: l_email }, align: :right),
				{ kind: :email_box, key: :email, value: person&.email, placeholder: l_email, mandatory: m_email, size: 17  }
			],
			[
				symbol_item(:user, { title: l_nick }, align: :right),
				{ kind: :text_box, key: :nick, size: 8, value: person&.nick, placeholder: l_nick }
			]
		]
		res
	end

	# return FieldComponents for form user personal data
	def user_form_pass
		[
			[
				symbol_item(:key),
				{ kind: :password_box, key: :password, placeholder: I18n.t("password.single"), mandatory: { length: 8 } }
			],
			[
				symbol_item(:key),
				{ kind: :password_box, key: :password_confirmation, placeholder: I18n.t("password.confirm"), mandatory: { length: 8 } }
			],
			[
				gap_item,
				{ kind: :text, value: I18n.t("password.confirm_label"), cols: 2, class: "text-xs" }
			]
		]
	end

	# return FieldComponents for form user role
	def user_form_role
		res = [
			[
				symbol_item(:key, { title: User.fld(:profile) }),
				{ kind: :select_box, align: "left", key: :role, options: User.role_list, value: @user.role }
			]
		]
		res.last <<	gap_item
		res.last << symbol_item(:locale, { title: I18n.t("locale.lang") })
		res.last << { kind: :select_box, align: :center, key: :locale, options: User.locale_list, value: @user.locale }
		res.last << hidden_input(:rdx, @rdx) if @rdx
		res
	end

	# return user_actions TableComponent
	def user_actions_title
		res  = title_start(title: @user.person.s_name, icon: user_actions_symbol)
		res << [ { kind: :subtitle, value: UserAction.label(:short) } ]
	end

	# return user_actions TableComponent
	def user_actions_table
		res = [ [
			topcell_item(I18n.t("calendar.date")),
			topcell_item(Drill.fld(:description))
		] ]
		@user.user_actions.order(updated_at: :desc).each { |u_act|
			res << [
				{ kind: :string, value: u_act.date_time, class: "border px-1 py-1" },
				{ kind: :string, value: u_act.description, class: "border px-1 py-1" }
			]
		}
		res
	end

	# prepare clear button only if there are actions to clear
	def user_actions_clear
		return nil if @user.user_actions.empty?
		{ kind: :clear, url: clear_actions_user_path(rdx: @rdx), name: @user.s_name }
	end

	# return table for @users TableComponent
	def user_table(users: @users)
		title = [
			{ kind: :normal, value: Club.label },
			{ kind: :normal, value: Person.fld(:name) },
			{ kind: :normal, value: User.fld(:profile), align: :center },
			{ kind: :normal, value: Person.fld(:contact), align: :center },
			{ kind: :normal, value: I18n.t("user.last_in"), align: :center }
		]
		title << normal_button({ kind: :add, url: new_user_path(rdx: @rdx), frame: :modal }) if @policy.new?

		rows = Array.new
		@users.each { |user|
			row = { url: path_for(user, search: @search), items: [] }
			row[:items] << (user.active? ? icon_item(user.club.logo) : symbol_item("no"))
			row[:items] << { kind: :normal, value: user.s_name }
			row[:items] << user_roles(user, table: true).first
			row[:items] << { kind: :contact, phone: user.person.phone, email: user.person.email }
			row[:items] << { kind: :normal, value: user.last_sign_in_at&.to_date, align: :center }
			row[:items] << normal_button({ kind: :delete, url: row[:url], name: user.s_name }) if @policy.destroy?
			rows << row
		}
		{ title:, rows:, align: :center }
	end

	private
		# tails actions_symbol to mark if log is quite full
		def user_actions_symbol
			symbol_hash(:actions, variant: @user.user_actions.count>10 ? "full" : "default")
		end
end

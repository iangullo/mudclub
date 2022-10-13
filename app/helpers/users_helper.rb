module UsersHelper
	# return icon and top of HeaderComponent
	def user_title_fields(title, icon: "user.svg", rows: 2, cols: nil, size: nil, _class: nil)
		title_start(icon: icon, title: title, rows: rows, cols: cols, size: size, _class: _class)
	end

	# return grid for @users GridComponent
	def user_grid(users:)
		title = [
			{kind: "normal", value: I18n.t("person.name")},
			{kind: "normal", value: I18n.t("role.player_a"), align: "center"},
			{kind: "normal", value: I18n.t("role.coach_a"), align: "center"},
			{kind: "normal", value: I18n.t("role.admin_a"), align: "center"}
		]
		title << {kind: "add", url: new_user_path, frame: "modal"} if current_user.admin? or current_user.is_coach?

		rows = Array.new
		users.each { |user|
			row = {url: user_path(user), frame: "modal", items: []}
			row[:items] << {kind: "normal", value: user.s_name}
			row[:items] << {kind: "icon", value: user.is_player? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << {kind: "icon", value: user.is_coach? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << {kind: "icon", value: user.admin? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << {kind: "delete", url: row[:url], name: user.s_name} if current_user.admin? and user.id!=current_user.id
			rows << row
		}
		{title: title, rows: rows}
	end

	def user_show_fields(user:)
		res = user_title_fields(user.s_name, icon: user.picture, _class: "rounded-full")
		res << []
		res.last << {kind: "icon", value: "player.svg"} if user.is_player?
		res.last << {kind: "icon", value: "coach.svg"} if user.is_coach?
		res.last << {kind: "icon", value: "key.svg"} if user.admin?
		res
	end

	# return FieldComponents for form title
	def user_form_title(title:, user:)
		res = user_title_fields(title, icon: user.picture, rows: 4, cols: 2, size: "100x100", _class: "rounded-full")
		res << [{kind: "label", value: I18n.t("person.name_a")}, {kind: "text-box", key: :name, value: user.person.name}]
		res << [{kind: "label", value: I18n.t("person.surname_a")}, {kind: "text-box", key: :surname, value: user.person.surname}]
		res << [{kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: user.person.birthday}]
		res
	end

	# return FieldComponents for form user role
	def user_form_role(user:)
		if current_user.admin?
			res = [[{kind: "label", value: "#{I18n.t("user.profile")}:"}, {kind: "select-box", align: "center", key: :role, options: User.role_list, value: user.role}]]
		else
			res = [[{kind: "label", align: "center", value: I18n.t(user.role)}]]
		end
		res
	end

	# return FieldComponents for form user avatar
	def user_form_avatar(user:)
		[[{kind: "upload", key: :avatar, label: I18n.t("person.pic"), value: user.avatar.filename}]]
	end

	# return FieldComponents for form user personal data
	def user_form_person(user:)
		[
			[{kind: "label", value: I18n.t("person.pid_a"), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: user.person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: user.person.email}],
			[{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: user.person.nick}, {kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: user.person.phone}]
		]
	end

	# return FieldComponents for form user personal data
	def user_form_pass(user:)
		[
			[{kind: "icon", value: "key.svg"}, {kind: "password-box", key: :password, auto: I18n.t("password.single")}],
			[{kind: "icon", value: "key.svg"}, {kind: "password-box", key: :password_confirmation, auto: I18n.t("password.confirm")}],
			[{kind: "gap"}, {kind: "text", value: I18n.t("password.confirm_label"), cols: 2, class: "text-xs"}]
		]
	end
end

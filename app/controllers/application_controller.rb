class ApplicationController < ActionController::Base
	around_action :switch_locale

	def switch_locale(&action)
		locale = params[:locale] || I18n.default_locale
		I18n.with_locale(locale, &action)
	end

	# redirect to / unless correct access level exists
	# works as "present AND (valid(role) OR valid(obj.condition))"
	def check_access(roles:, obj: nil, returl: nil)
		res = false
		if current_user.present?
			returl = "/" unless returl  # redirect to / by default if user is present
			roles.each { |rol|
				case rol  # ok as if any of roles is found
				when :admin then res = current_user.admin?
				when :coach then res = current_user.is_coach?
				when :player then res = current_user.is_player?
				when :user then res = true  # it's a user alright
				end
				break if res
			}
			unless res # check for OBJ related conditions
				case obj
				when Coach then res = current_user.person.coach_id==obj.id
				when Drill then res = current_user.person.coach_id==obj.coach_id
				when Event then res = obj.team.has_coach(current_user.person.coach_id)
				when Person then res = current_user.person.id==obj.id
				when Player then res = current_user.person.player_id==obj.id
				when Team then res = obj.has_coach(current_user.person.coach_id)
				when User then res = current_user.id==@user.id
				end
			end
		else
			returl = "/"
		end
		redirect_to returl, data: {turbo_action: "replace"} unless res
	end
end

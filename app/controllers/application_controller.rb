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
class ApplicationController < ActionController::Base
	around_action :switch_locale

	def switch_locale(&action)
		locale = params[:locale] ? params[:locale] : (current_user.try(:locale) || I18n.default_locale)
		I18n.with_locale(locale, &action)
	end

	# check if correct  access level exists
	# works as "present AND (valid(role) OR valid(obj.condition))"
	def check_access(roles:, obj: false)
		res = false
		if current_user.present?
			admin   = current_user.admin?
			coachid = current_user.person.coach_id
			persid  = current_user.person.id
			playid  = current_user.person.player_id
			roles.each { |rol|	# ok as if any of roles is found
				case rol
				when :admin then res = admin
				when :coach then res = current_user.is_coach?
				when :player then res = current_user.is_player?
				when :user then res = true  # it's a user alright
				end
				break if res
			}
			if res # additional check for OBJ related conditions
				case obj
				when Category, Division, Location, Season, Slot then res = true
				when Coach then res = (admin or coachid==obj.id)
				when Drill then res = (admin or coachid==obj.coach_id)
				when Event then res = (admin or obj.team.has_coach(coachid))
				when Person then res = (admin or persid==obj.id)
				when Player then res = (admin or current_user.is_coach? or playid==obj.id)
				when Team then res = (admin or obj.has_coach(coachid))
				when User then res = (admin or current_user.id==@user.id)
				when NilClass then res = false
				end
			end
		end
		res
	end

	# return FieldsComponent object from a fields array
	def create_fields(fields)
		FieldsComponent.new(fields:)
	end

	# return GridComponent object from a grid hash
	def create_grid(grid)
		grid ? GridComponent.new(grid:) : nil
	end

	# Create a submit component
	def create_submit(close: "close", submit: "save", close_return: nil, frame: nil)
		SubmitComponent.new(close:, submit:, close_return:, frame:)
	end
end

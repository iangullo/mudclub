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
class Target < ApplicationRecord
	has_many :team_targets
	has_many :teams, through: :team_targets
	has_many :drill_targets
	has_many :drills, through: :drill_targets
	has_many :event_targets
	has_many :events, through: :event_targets
  scope :orphans, lambda {
		left_outer_joins(:teams, :events, :drills)
		.where("(teams.id IS NULL OR teams.id = 0)")
		.where("(events.id IS NULL OR events.id = 0)")
		.where("(drills.id IS NULL OR drills.id = 0)")
		.distinct
	}
	self.inheritance_column = "not_sti"

	enum aspect: {
		general: 0,
		individual: 1,
		collective: 2,
		strategy: 3
	}
	enum focus: {
		physical: 0,
		offense: 1,
		defense: 2
	}

	def self.aspects
		res = Array.new
		res << [I18n.t("target.aspect.gen"), 0]
		res << [I18n.t("target.aspect.ind"), 1]
		res << [I18n.t("target.aspect.col"), 2]
#    res << [I18n.t("target.aspect.str"),3]
	end

	def self.kinds
		res = Array.new
		res << [I18n.t("target.focus.fit"), 0]
		res << [I18n.t("target.focus.ofe"), 1]
		res << [I18n.t("target.focus.def"), 2]
	end

	# Search target matching. returns either nil or a Target
	def self.fetch(id, concept, focus=nil, aspect=nil)
		res = id ? Target.find(id.to_i) : nil
		if res==nil and concept
			if concept.strip.length > 0
				res = Target.where("unaccent(concept) ILIKE unaccent(?)","%#{concept.strip}%")
			else
				res = Target.real
			end
			res = focus ? res.where(focus: focus.length==1 ? focus.to_i : focus.to_sym) : res
			res = aspect ? res.where(aspect: aspect.length==1 ? aspect.to_i : aspect.to_sym) : res
			res = res ? res.first : nil
		end
		return res
	end

	# return list of registered Targets ordered by concept
	def self.list(focus: nil,aspect: nil)
		res  = []
		Target.fetch(nil,"",focus,aspect).order(:concept).each {|target|
			res << target.concept
		}
		res	end
end

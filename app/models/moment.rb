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
# Moment - timestamped coaching note on the video of a match.
# Tagged to a player, or to the whole team when player is nil.
class Moment < ApplicationRecord
	belongs_to :event
	belongs_to :player, optional: true
	enum :kind, %i[note good improve]
	scope :ordered, -> { order(:second, :id) }
	# moments a player may see: whole-team ones plus those tagged to them
	scope :visible_to, ->(player_id) { where(player_id: [ nil, player_id ].uniq) }
	validates :note, presence: true, length: { maximum: 200 }
	validate :valid_time, :player_in_team

	# list of kinds for select box configuration
	def self.kind_list
		Moment.kinds.keys.map { |kind| [ I18n.t("moment.kind.#{kind}"), kind ] }
	end

	# video position as "m:ss" (or "h:mm:ss")
	def time
		hours, rest = self.second.to_i.divmod(3600)
		mins, secs  = rest.divmod(60)
		hours > 0 ? format("%d:%02d:%02d", hours, mins, secs) : format("%d:%02d", mins, secs)
	end

	# accepts "ss", "m:ss" or "h:mm:ss" strings
	def time=(t_string)
		parts = t_string.to_s.strip.split(":")
		if parts.size.between?(1, 3) && parts.all? { |part| part.match?(/\A\d+\z/) }
			self.second = parts.map(&:to_i).inject(0) { |total, part| (total * 60) + part }
		else
			self.second = nil	# fails valid_time validation
		end
	end

	private
		def valid_time
			errors.add(:second, I18n.t("moment.bad_time")) unless self.second.is_a?(Integer) && self.second >= 0
		end

		def player_in_team
			return unless self.player && self.event
			errors.add(:player, I18n.t("moment.bad_player")) unless self.event.team.has_player(self.player.id)
		end
end

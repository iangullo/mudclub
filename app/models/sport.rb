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
# simple class to have configurable Sports linked to the Club
class Sport < ApplicationRecord
	has_many :categories, dependent: :nullify
	has_many :divisions, dependent: :nullify
	has_many :teams, dependent: :nullify

	# multi-language string for sport name
	def to_s
		I18n.t("sport.#{self.name}")
	end

	# Getter method for accessing the settings hash
	def settings
    super&.symbolize_keys || {}
	end

	# Setter method for updating the settings hash
	def settings=(value)
		super(value&.to_h)
	end

	# Getter method for accessing the Sport rules mapping
	def rules
		settings&.fetch(:rules, {})
	end

	# the default rules to apply in a category
	def def_rules

	end

	# Setter method for updating the rules mapping
	def rules=(value)
		set_setting(:rules, value)
	end

	# Getter method for accessing the stat mapping
	def stats
		settings&.fetch(:stats, {})
	end

	# Setter method for updating the stat mapping
	def stats=(value)
		set_setting(:stats, value)
	end

	# Getter method for accessing the Sport rules mapping
	def stat_kinds
		settings&.fetch(:stat_kinds, {})
	end

	# Setter method for updating the rules mapping
	def stat_kinds=(value)
		set_setting(:stat_kinds, value)
	end

	private
	# generic setting method to be used for all setters
	def set_setting(key, value)
		self.settings = settings.merge(key => value)
	end
end

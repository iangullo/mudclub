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
# Manage mixture of canonical & user-defined catalog entries
# used by Drill category autocompletion to specify Drills.
#
class DrillCategory < ApplicationRecord
	localized_as "training.drill_category"

	before_save { self.name = self.name.mb_chars.titleize }

	#-------------------------------------
	# Class relationships
	#-------------------------------------
	self.inheritance_column = "not_sti"
	belongs_to :sport, optional: true
	has_many :drills

	scope :real,		-> { where("id>0").order(:name) }
	scope :seeded,  -> { where.not(catalog_key: nil) }
	scope :orphans, -> { left_outer_joins(:drills).where("drills.id IS NULL OR drills.id = 0") }
	pg_search_scope :search,
		against: :name,
		ignoring: :accents,
		using: { tsearch: { prefix: true } }

	# -------------------------------------------------------------------------
	# Transitional helpers.
	#
	# `fetch` and `list` keep the same shape as the legacy `Kind` model so
	# call sites in the Drill form work unchanged during the migration window.
	# New code should prefer the seeded-catalog lookup (Phase 2) instead.
	# -------------------------------------------------------------------------

	def self.fetch(name, sport: nil)
		key = name.to_s.strip
		return nil if key.blank?
		find_or_create_by!(sport:, name: key)
	end

	def self.list(sport: nil)
		return real.pluck(:name) unless sport
		real.where("sport_id = ? OR sport_id IS NULL", sport.id).pluck(:name)
	end

	def self.options(sport: nil)
		return real.pluck(:name, :id) unless sport
		real.where("sport_id = ? OR sport_id IS NULL", sport.id).pluck(:name, :id)
	end
end

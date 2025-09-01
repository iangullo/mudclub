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
# Manage Drill/Plays in the model
class Drill < ApplicationRecord
	FILTER_PARAMS = %i[name kind_id season_id skill column direction].freeze
	before_destroy :unlink
	has_paper_trail on: [ :create, :update ]
	belongs_to :sport
	belongs_to :coach
	belongs_to :kind
	has_and_belongs_to_many :skills
	accepts_nested_attributes_for :skills, reject_if: :all_blank, allow_destroy: true
	has_many :drill_targets, dependent: :destroy
	has_many :targets, through: :drill_targets
	has_many :tasks, dependent: :destroy
	accepts_nested_attributes_for :targets, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :drill_targets, reject_if: :all_blank, allow_destroy: true
	has_one_attached :playbook
	has_rich_text :explanation
	has_many :steps, dependent: :destroy
	accepts_nested_attributes_for :steps, reject_if: :all_blank, allow_destroy: true
	pg_search_scope :search_by_name,
		against: [ :name, :description ],
		ignoring: :accents,
		using: { tsearch: { prefix: true } }
	scope :real, -> { where("id>0") }
	scope :by_name, ->(name) { name.present? ? search_by_name(name) : all }
	scope :by_kind, ->(kind_id) { (kind_id.to_i > 0) ? where(kind_id: kind_id.to_i) : all }
	scope :by_season, ->(season) { season.present? ? where(updated_at: season.start_date..season.end_date).distinct : all	}
	scope :by_skill, ->(skill) { skill.present? ? where(id: Drill.joins(:skills).merge(Skill.search(skill)).pluck(:id)).distinct : all	}
	self.inheritance_column = "not_sti"
	validates :name, presence: true

	# human name of a specific :court
	def court_name
		self.sport.court_name(self.court_mode)
	end	# wrapper to return image symbol to self court_mode

	# wrapper to return image symbol to self court_mode
	def court_symbol
		self.sport.symbol(self.court_mode, type: :court)
	end

	# check if drill (or associations) has changed
	def modified?
		res = self.changed?
		unless res
			res = self.steps.any?(&:saved_changes?)
			unless res
				res = self.skills.any?(&:saved_changes?)
				unless res
					res = self.drill_targets.any?(&:saved_changes?)
				end
			end
		end
		res
	end

	# A longer string with kind included
	def nice_string
		cad = self.kind_id ? (self.kind.name + " | ") : ""
		cad = cad + (self.name ? self.name : I18n.t("drill.default"))
		cad
	end


	# Array of print strings for associated skills
	def print_skills
		print_names(self.skills)
	end

	# Array of print strings for associated targets
	def print_targets(array: true)
		zero = !array
		cad  = (array ? [] : "")
		self.drill_targets.each do |tgt|
			if array
				cad << tgt.to_s
			else
				if zero
					zero = false
					cad  = tgt.to_s
				else
					cad += "\n\t#{tgt}"
				end
			end
		end
		cad
	end

	# build new @drill from raw input hash given by form submital submittal
	# return nil if unsuccessful
	def rebuild(f_data)
		self.name        = f_data[:name]
		self.description = f_data[:description]
		self.material    = f_data[:material]
		self.coach_id    = f_data[:coach_id]
		self.court_mode  = f_data[:court_mode]
		self.kind_id     = Kind.fetch(f_data[:kind_id]&.strip).id
		self.playbook    = f_data[:playbook]
		self.check_steps(f_data[:steps_attributes]) if f_data[:steps_attributes]
		self.check_skills(f_data[:skills_attributes]) if f_data[:skills_attributes]
		self.check_targets(f_data[:drill_targets_attributes]) if f_data[:drill_targets_attributes]
		self
	end

	# return the season of last update for a Drill.
	def season_string
		season = Season.where("start_date <= ? and end_date >= ?", self.updated_at, self.updated_at).distinct.first
		season&.name
	end

	# temporary wrappers to access :explanation as Step 1 :explanation
	def step_explanation(order = 1)
		steps.find_by(order:)&.explanation
	end

	def step_explanation=(value, order = 1)
		step = steps.find_or_initialize_by(order:)
		step.explanation = value
		step.save!
	end

	# Apply a Filter to Drills using params received from a controller.
	def self.filter(filters)
		if filters.present?
			name   = filters["name"]&.presence
			kind   = filters["kind_id"]&.to_i
			skill  = filters["skill"]&.presence
			season = Season.find(filters["season_id"]&.presence) if filters["season_id"]&.present?
			if name || kind || skill || season
				res = Drill.by_name(name).by_kind(kind).by_skill(skill).by_season(season)
				filters["column"] ? res.order("#{filters['column']} #{filters['direction']}") : res.order(:name)
			else
				res = Drill.none
			end
		else
			res = Drill.all
		end
		res
	end

	# search all drills for specific subsets
	def self.search(search = nil)
		if search.present?
			s_type = "name"
			res    = Drill.all
			search.scan(/\s*\w+\s*/).each { |cad|	# scan the search string  for tokens
				case cad
				when "k"	# next string ought to be a kind
					s_type = "kind"
				when "s"	# next string ought to be a skill
					s_type = "skill"
				when "t"	# next string ought to be a target
					s_type = "target"
				else	# a sub search string
					cad = cad.rstrip
					case s_type	# apply the right token
					when "kind"
						res = self.search_kind(res, cad)
						s_type = "name"
					when "skill"
						res = self.search_skill(res, cad)
						s_type = "name"
					when "target"
						res = self.search_target(res, cad)
						s_type = "name"
					when "name"
						res = self.search_name(res, cad)
					end
				end
			}
		else
			res = Drill.real
		end
		res.order(:kind_id)
	end

	# filter drills by kind
	def self.search_kind(res = Drill.all, s_k)
		res = res.where(kind_id: Kind.search(s_k)).distinct
	end

	# filter by name/description
	def self.search_name(res = Drill.all, s_n)
		res = res.search_by_name(s_n)
	end

	# filter drills by season
	def self.search_season(res = Drill.all, s_s)
		season = Season.search(s_s)&.updated_at
		res = season ? res.where(updated_at: season.start_date..season.end_date).distinct : res
	end

	# filter for fundamentals
	def self.search_skill(res = Drill.all, s_s)
		res = res.joins(:skills).where(skills: Skill.search(s_s)).distinct
	end

	# filter for targets
	def self.search_target(res = Drill.all, s_t)
		res = res.joins(:targets).where(targets: Target.fetch(nil, s_t)).distinct
	end

	private
		# checks skills array received and manages adding/removing
		# from the drill collection - remove duplicates from list
		def check_skills(s_array)
			a_skills = Array.new	# array to include only non-duplicates
			s_array.each { |s| # first pass
				# s[1][:name] = s[1][:name].mb_chars.titleize
				a_skills << s[1] # unless a_skills.detect { |a| a[:name] == s[1][:name] }
			}
			a_skills.each { |s| # second pass - manage associations
				sk = Skill.fetch(s)
				if s[:_destroy] == "1"
					self.skills.delete(sk)
				else	# add to collection
					sk = Skill.create(concept: s[:concept].strip) unless sk
					self.skills << sk unless self.skills.include?(sk)
				end
			}
		end

		# checks skills array received and manages adding/removing
		# from the drill collection - remove duplicates from list
		def check_steps(s_array)
			a_steps = Step.passed(s_array) # array to include only non-duplicates
			binding.break
			a_steps.each { |s| # second pass - manage associations
				st = Step.find_by_id(s[:id].to_i)
				if s[:_destroy] == "1"
					self.steps.delete(s[:id].to_i)
					st.delete if st&.persisted?
				elsif s[:explanation].present? || st[:svgdata].present? || st[:explanation].present? || st[:diagram].present?	# add to collection
					st ||= Step.new(drill_id: self.id, order: s[:order].presence)
					st.diagram = s[:diagram] if s[:diagram].presence
					st.svgdata = s[:svgdata] if s[:svgdata].presence
					st.explanation = s[:explanation].presence
					st.save
					self.steps << st unless self.steps.include?(st)
				elsif st	# empty step => delete it
					st.delete
				end
			}
			i = 1
			self.steps.order(:order).each do |step|	# ensure correct ordering
				step.update! order: i
				i += 1
			end
		end

		# checks targets_attributes array received and manages adding/removing
		# from the target collection - remove duplicates from list
		def check_targets(t_array)
			a_targets = Target.passed(t_array)
			priority  = 1
			a_targets.each do |t| # second pass - manage associations
				if t[:_destroy] == "1"	# remove drill_target
					self.targets.delete(t[:target_attributes][:id].to_i)
				else
					dt = DrillTarget.fetch(t)
					dt.update(priority:)
					priority += 1
					self.drill_targets ? self.drill_targets << dt : self.drill_targets |= dt
				end
			end
		end

		def print_names(obj_array)
			i = 0
			aux = ""
			obj_array.each { |obj|
				aux = (i == 0) ? obj.concept : aux + "; " + obj.concept
				i += 1
			}
			aux
		end

		# cleanup dependent teams, reassigning to 'dummy' category
		def unlink
			self.skills.delete_all
			self.playbook.purge if self.playbook.attached?
			UserAction.prune("/drills/#{self.id}")
		end
end

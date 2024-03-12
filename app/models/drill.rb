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
class Drill < ApplicationRecord
	before_destroy :unlink
	has_paper_trail on: [:create, :update]
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
	pg_search_scope :search_by_name,
		against: [:name, :description],
		ignoring: :accents,
		using: { tsearch: {prefix: true} }
	scope :real, -> { where("id>0") }
	scope :by_name, -> (name) { name.present? ? search_by_name(name) : all }
	scope :by_kind, -> (kind_id) { (kind_id.to_i > 0) ? where(kind_id: kind_id.to_i) : all }
	scope :by_skill, -> (skill) { skill.present? ? where(id: Drill.joins(:skills).merge(Skill.search(skill)).pluck(:id)).distinct : all	}
	self.inheritance_column = "not_sti"
	validates :name, presence: true
	FILTER_PARAMS = %i[name kind_id skill column direction].freeze

	def self.filter(filters)
		if filters.present?
			name  = filters["name"]&.presence
			kind  = filters["kind_id"]&.to_i
			skill = filters["skill"]&.presence
			if name || kind || skill
				res = Drill.by_name(name).by_kind(kind).by_skill(skill)
				filters['column'] ? res.order("#{filters['column']} #{filters['direction']}") : res.order(:name)
			else
				res = Drill.none
			end
		else
			res = Drill.none
		end
		return res
	end

	# search all drills for specific subsets
	def self.search(search=nil)
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

	# filter by name/description
	def self.search_name(res=Drill.all, s_n)
		res = res.search_by_name(s_n)
	end

	# filter drills by kind
	def self.search_kind(res=Drill.all, s_k)
		res = res.where(kind_id: Kind.search(s_k)).distinct
	end

	# filter for fundamentals
	def self.search_skill(res=Drill.all, s_s)
		res = res.joins(:skills).where(skills: Skill.search(s_s)).distinct
	end

	# filter for targets
	def self.search_target(res=Drill.all, s_t)
		res = res.joins(:targets).where(targets: Target.fetch(nil, s_t)).distinct
	end

	# check if drill (or associations) has changed
	def modified?
		res = self.changed?
		unless res
			res = self.explanation.changed?
			unless res
				res = self.skills.any?(&:saved_changes?)
				unless res
					res = self.drill_targets.any?(&:saved_changes?)
				end
			end
		end
		res
	end

	# Array of print strings for associated skills
	def print_skills
		print_names(self.skills)
	end

	# Array of print strings for associated targets
	def print_targets
		cad = []
		self.drill_targets.each { |tgt|
			cad << tgt.to_s
		}
		cad
	end

	# A longer string with kind included
	def nice_string
		cad = self.kind_id ? (self.kind.name + " | ") : ""
		cad = cad + (self.name ? self.name : I18n.t("drill.default"))
		cad
	end

	# build new @drill from raw input hash given by form submital submittal
	# return nil if unsuccessful
	def rebuild(f_data)
		self.name        = f_data[:name]
		self.description = f_data[:description]
		self.material    = f_data[:material]
		self.coach_id    = f_data[:coach_id]
		self.kind_id     = Kind.fetch(f_data[:kind_id]&.strip).id
		self.explanation = f_data[:explanation]
		self.playbook    = f_data[:playbook]
		self.check_skills(f_data[:skills_attributes]) if f_data[:skills_attributes]
		self.check_targets(f_data[:drill_targets_attributes]) if f_data[:drill_targets_attributes]
		self
	end

	# checks skills array received and manages adding/removing
	# from the drill collection - remove duplicates from list
	def check_skills(s_array)
		a_skills = Array.new	# array to include only non-duplicates
		s_array.each { |s| # first pass
			#s[1][:name] = s[1][:name].mb_chars.titleize
			a_skills << s[1] #unless a_skills.detect { |a| a[:name] == s[1][:name] }
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

	# checks targets_attributes array received and manages adding/removing
	# from the target collection - remove duplicates from list
	def check_targets(t_array)
		a_targets = Array.new	# array to include only non-duplicates
		t_array.each { |t| # first pass
			a_targets << t[1] unless a_targets.detect { |a| a[:target_attributes][:concept] == t[1][:target_attributes][:concept].strip }
		}
		a_targets.each { |t| # second pass - manage associations
			if t[:_destroy] == "1"	# remove drill_target
				self.targets.delete(t[:target_attributes][:id])
			else
				dt = DrillTarget.fetch(t)
				self.drill_targets ? self.drill_targets << dt : self.drill_targets |= dt
			end
		}
	end

	private
		def print_names(obj_array)
			i = 0
			aux = ""
			obj_array.each { |obj|
				aux = (i == 0) ? obj.concept : aux + "; " + obj.concept
				i = i +1
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

class Drill < ApplicationRecord
	belongs_to :coach
	belongs_to :kind
	has_and_belongs_to_many :skills
	accepts_nested_attributes_for :skills, reject_if: :all_blank, allow_destroy: true
	has_many :drill_targets
  has_many :targets, through: :drill_targets
	accepts_nested_attributes_for :targets, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :drill_targets, reject_if: :all_blank, allow_destroy: true
	has_one_attached :playbook
	has_rich_text :explanation
	scope :real, -> { where("id>0") }
	self.inheritance_column = "not_sti"

	# search all drills for specific subsets
	def self.search(search=nil)
		if search and search.length > 0
			s_type = "name"
			res = Drill.all
			search.scan(/\s*\w+\s*/).each { |s|	# scan the search string  for tokens
				case s
				when "k"	# next string ought to be a kind
					s_type = "kind"
				when "s"	# next string ought to be a skill
					s_type = "skill"
				when "t"	# next string ought to be a target
					s_type = "target"
				else	# a sub search string
					case s_type	# apply the right token
					when "kind"
						res = self.search_kind(res, search)
						s_type = "name"
					when "skill"
						res = self.search_kind(res, search)
						s_type = "name"
					when "target"
						res = self.search_kind(res, search)
						s_type = "name"
					when "name"
						res = self.search_name(res, search)
					end
				end
			}
		else
			res = Drill.real
		end
		res.order(:kind_id)
	end

	# filter by name/description
	def self.search_name(res=Drill.all, search)
		s_n = search.scan(/\s*(\w\w+)\s+\w=\w+.*/)
		if s_n # matched something
			unless s_n.empty?
				s_n = s_n.first.first
				res = res.where("unaccent(name) ILIKE unaccent(?) OR unaccent(description) ILIKE unaccent(?)","%#{s_n}%","%#{s_n}%")
			end
		end
		return res
	end

	# filter drills by kind
	def self.search_kind(res=Drill.all, search)
		s_k = search.scan(/k=(\w+)/)
		if s_k # matched something
			unless s_k.empty?
				s_k = s_k.first.first
				res = res.where(kind_id: Kind.search(s_k))
			end
		end
		return res
	end

	# filter for fundamentals
	def self.search_skill(res=Drill.all, search)
		s_s = search.scan(/s=(\w+)/)
		if s_s # matched something
			unless s_s.empty?
				s_s = s_s.first.first
				res = res.joins(:skills).where(skills: Skill.search(s_s))
			end
		end
		return res
	end

	# filter for fundamentals
	def self.search_target(res=Drill.all, search)
		s_t = search.scan(/t=(\w+)/)
		if s_t # matched something
			unless s_t.empty?
				s_t = s_t.first.first
				res = res.joins(:targets).where(targets: Target.search(nil, s_t))
			end
		end
		return res
	end

	def print_skills
		print_names(self.skills)
	end

	# print strings for associated targets
	def print_targets
		cad = nil
		self.drill_targets.each { |tgt|
			cad = cad ?  cad + "\n" + tgt.to_s  : tgt.to_s
		}
		cad
	end

	def nice_string
		cad = self.kind_id ? (self.kind.name + " | ") : ""
		cad = cad + (self.name ? self.name : "<NEW DRILL>")
		cad
	end

#	def print_kinds
#		print_names(self.kinds)
#	end

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
end

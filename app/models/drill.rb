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
	scope :by_name, -> (name) { where("unaccent(name) ILIKE unaccent(?) OR unaccent(description) ILIKE unaccent(?)","%#{name}%","%#{name}%").distinct }
	scope :by_kind, -> (kind_id) { (kind_id and kind_id.to_i>0) ? where(kind_id: kind_id.to_i) : where("kind_id>0") }
	scope :by_skill, -> (skill_id) { (skill_id and skill_id.to_i>0) ? joins(:skills).where(skills: {id: skill_id.to_i}) : all	}
	self.inheritance_column = "not_sti"
  FILTER_PARAMS = %i[name kind_id skill_id column direction].freeze

	def self.filter(filters)
		Drill.by_name(filters['name'])
		.by_kind(filters['kind_id'])
		.by_skill(filters['skill_id'])
		.order("#{filters['column']} #{filters['direction']}")
	end

	# search all drills for specific subsets
	def self.search(search=nil)
		if search and search.length > 0
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
		res = res.where("unaccent(name) ILIKE unaccent(?) OR unaccent(description) ILIKE unaccent(?)","%#{s_n}%","%#{s_n}%").distinct
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
		res = res.joins(:targets).where(targets: Target.search(nil, s_t)).distinct
	end

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

	def nice_string
		cad = self.kind_id ? (self.kind.name + " | ") : ""
		cad = cad + (self.name ? self.name : I18n.t("drill.default"))
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

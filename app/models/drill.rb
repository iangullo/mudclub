class Drill < ApplicationRecord
	belongs_to :coach
	belongs_to :kind
	has_and_belongs_to_many :skills
	accepts_nested_attributes_for :skills, reject_if: :all_blank, allow_destroy: true
	has_rich_text :explanation
	before_save { self.name = self.name.mb_chars.titleize }
	self.inheritance_column = "not_sti"

	# filter by name/description
	def self.search(search)
		s_n = search ? (search.length>0 ? search : nil) : nil
		if s_n # matched something
			res = Drill.where("unaccent(name) ILIKE unaccent(?) OR unaccent(description) ILIKE unaccent(?)","%#{s_n}%","%#{s_n}%")
		else
			res = Drill.all.order(:kind_id)
		end
		return res
	end

	def print_skills
		print_names(self.skills)
	end

#	def print_kinds
#		print_names(self.kinds)
#	end

	private
	def print_names(obj_array)
		i = 0
		aux = ""
		obj_array.each { |obj|
			aux = (i == 0) ? obj.name : aux + "; " + obj.name
			i = i +1
		}
		aux
	end
end

class Drill < ApplicationRecord
	belongs_to :coach
	belongs_to :kind
#	accepts_nested_attributes_for :kind
	has_and_belongs_to_many :skills
	accepts_nested_attributes_for :skills, reject_if: :all_blank, allow_destroy: true
	has_rich_text :explanation
	has_one_attached :video
#	has_many_attached :images
#	attr_accessor :new_images
	before_save { self.name = self.name.mb_chars.titleize }
	self.inheritance_column = "not_sti"

#	def attach_images
#		return if new_images.blank?
#
#		images.attach(new_images)
#		self.new_images = []
#	end

	def print_skills
		print_names(self.skills)
	end

	def self.search(search)
		if search
			Drill.where(kind_id: Kind.where(["name LIKE ? ","%#{search}%"])).or(["name LIKE ? OR description LIKE ? ","%#{search}%","%#{search}%"]).order(:kind)
		else
			#Drill.all.order(:kind)
			Drill.none
		end
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

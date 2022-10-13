class Location < ApplicationRecord
	scope :practice, -> { where("practice_court = true") }
	scope :home, -> { where("id > 0 and practice_court = false") }
	scope :real, -> { where("id > 0") }
	has_many :slots
	has_many :events
	has_many :season_locations
	has_many :seasons, through: :season_locations
	accepts_nested_attributes_for :seasons
	self.inheritance_column = "not_sti"

	def to_s
		self.name
	end

	# checks if it exists in the collection before adding it
	# returns: reloads self if it exists in the database already
	# 	   'nil' if it needs to be created.
	def exists?
		p = Location.where(name: self.name)
		if p.try(:size)==1
			self.id = p.first.id
			self.reload
		else
			nil
		end
	end

	#Search field matching
	def self.search(search)
		if search
			search.length>0 ? Location.where("unaccent(name) ILIKE unaccent(?)","%#{search}%") : Location.real
		else
			Location.real
		end
	end

	# Ensure we remove dependencies of location before deleting.
	def scrub
		self.seasons.clear
		self.slots.each { |s|
			s.delete
		}
	end

	# rebuild @location from raw hash returned by a form
	def rebuild(l_data)
		self.name           = l_data[:name]
		self.exists? # reload from database
		self.gmaps_url      = l_data[:gmaps_url] if l_data[:gmaps_url].length > 0
		self.practice_court = (l_data[:practice_court] == "1")
	end
end

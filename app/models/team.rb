class Team < ApplicationRecord
	belongs_to :category
	belongs_to :division
	belongs_to :season
	has_and_belongs_to_many :players
	has_and_belongs_to_many :coaches
	has_many :training_slots
	has_many :training_sessions
#	accepts_nested_attributes_for :category
#	accepts_nested_attributes_for :division
#	accepts_nested_attributes_for :season
	accepts_nested_attributes_for :coaches
	accepts_nested_attributes_for :players
	accepts_nested_attributes_for :training_sessions
	default_scope { order(category_id: :asc) }
	scope :real, -> { where("id>0") }
	scope :for_season, -> (s_id) { where("season_id = ?", s_id) }

	def to_s
		if self.name and self.name.length > 0
			self.name.to_s
		else
			self.category.to_s
		end
	end

	# Get a list of players that are valid to play in this team
	def eligible_players
		s_year = self.season.name[0..3].to_i
		aux = Player.active.joins(:person).where("birthday > ? AND birthday < ?", self.category.oldest(s_year), self.category.youngest(s_year)).order(:birthday)
		if aux
			case self.category.sex
				when "Fem."
					aux = aux.female
				when "Masc."
					aux = aux.male
				else
					aux
			end
		end
		aux.order(:number)
	end

	#Search field matching season
	def self.search(search)
		if search
			s_id = search.to_i
			s_id > 0 ? Team.for_season(s_id).order(:category_id) : Team.real
		else
			Team.real
		end
	end

	def has_coach(c_id)
		self.coaches.find_index { |c| c[:id]==c_id }
	end

	def has_player(p_id)
		self.players.find_index { |p| p[:id]==p_id }
	end
end

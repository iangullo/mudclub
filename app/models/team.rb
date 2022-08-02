class Team < ApplicationRecord
	belongs_to :category
	belongs_to :division
	belongs_to :season
	has_and_belongs_to_many :players
	has_and_belongs_to_many :coaches
	has_many :slots
	has_many :events
	has_many :team_targets
  has_many :targets, through: :team_targets
#	accepts_nested_attributes_for :category
#	accepts_nested_attributes_for :division
#	accepts_nested_attributes_for :season
	accepts_nested_attributes_for :coaches
	accepts_nested_attributes_for :players
	accepts_nested_attributes_for :events
	accepts_nested_attributes_for :targets
	accepts_nested_attributes_for :team_targets
	default_scope { order(category_id: :asc) }
	scope :real, -> { where("id>0") }
	scope :for_season, -> (s_id) { where("season_id = ?", s_id) }
  enum rules: {
    fiba: 0,
    q4: 1,
    q6: 2
  }

	def to_s
		if self.name and self.name.length > 0
			self.name.to_s
		else
			self.category.to_s
		end
	end

	# Get a list of players that are valid to play in this team
	def eligible_players
		s_year = self.season.start_year
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

	def general_def(month=0)
    search_targets(month, 0, 2)
  end

  def general_off(month=0)
    search_targets(month, 0, 1)
  end

  def individual_def(month=0)
    search_targets(month, 1, 2)
  end

  def individual_off(month=0)
    search_targets(month, 1, 1)
  end

  def collective_def(month=0)
    search_targets(month, 2, 2)
  end

  def collective_off(month=0)
    search_targets(month, 2, 1)
  end

	# return next free training_slot
	# after the last existing one in the calendar
	def next_slot(last=nil)
		d   = last ? last.start_time.to_date : Date.today	# last planned slot date
		res = nil
		self.slots.each { |slot|
			s   = slot.next_date(d)
			res = res ? (s < res.next_date(d) ? slot : res) : slot
		}
		return res
	end

	# get attendance data for player over the period specified by "during"
	# returns a a total & serialised numbers for attendace: matches [%] & trainings [%]
	def attendance
		t_players  = self.players.count
		if t_players > 0
			m_count    = self.events.matches.this_season.count
			s_count    = self.events.trainings.this_season.count
			a_matches  = {name: I18n.t("match.many"), avg: 0, data: {}}
			a_sessions = {name: I18n.t("train.many"), avg: 0, data: {}}
			a_total    = {name: I18n.t("stat.total"), avg: 0, data: {}}
			self.events.normal.this_season.each { |event|
				e_att = event.players.count	# how many came?
				a_total[:data][event.start_date] = (100*e_att/t_players).to_i # add another to the series
				if event.match?
					a_matches[:data][event.start_date] = (100*e_att/t_players).to_i # add to matches
					a_matches[:avg] = a_matches[:avg] + e_att
				elsif event.train?
					a_sessions[:data][event.start_date] =  (100*e_att/t_players).to_i # add to sessions
					a_sessions[:avg] = a_sessions[:avg] + e_att
				end
			}
			a_total[:avg]    = (m_count+s_count)>0 ? (100*(a_matches[:avg] + a_sessions[:avg])/(t_players * (m_count + s_count))).to_i : nil
			a_matches[:avg]  = m_count>0 ? (100*a_matches[:avg] / (t_players * m_count)).to_i : nil
			a_sessions[:avg] = s_count > 0 ? (100*a_sessions[:avg] / (t_players * s_count)).to_i : nil
			{total: a_total, matches: a_matches, sessions: a_sessions}
		else
			nil	# NO PLAYERS IN THE TEAM --> NO ATTENDANCE DATA TO SHOW
		end
	end

	# return time rules that apply to this team
	def periods
		self.rules ? self.rules : self.category.def_rules
	end

private
	# search team_targets based on target attributes
	def search_targets(month=0, aspect=nil, focus=nil)
		#puts "Plan.search(team: " + ", month: " + month.to_s + ", aspect: " + aspect.to_s + ", focus: " + focus.to_s + ")"
		tgt = self.team_targets.monthly(month)
		res = Array.new
		tgt.each { |p|
			puts p.to_s
			if aspect and focus
				res.push p if ((p.target.aspect_before_type_cast == aspect) and (p.target.focus_before_type_cast == focus))
			elsif aspect
				res.push p if (p.target.aspect_before_type_cast == aspect)
			elsif focus
				res.push p if (p.target.focus_before_type_cast == focus)
			else
				res.push p
			end
		}
		res
	end
end

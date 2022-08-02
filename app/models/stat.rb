class Stat < ApplicationRecord
  belongs_to :event
  belongs_to :player  # id==0 => team stat; id==-1 => rival stat
  scope :real, -> { where("id>0") }
  scope :for_event, -> (e_id) { where("event_id==?", e_id) }
  scope :for_team, -> { where("player_id==0") }
  scope :for_rival, -> { where("player_id==-1") }
  scope :for_players, -> { where("player_id>0") }
  scope :for_player, -> (p_id) { where("player_id==?", p_id) }
  scope :for_concept, -> (cval) { where("concept==?", cval) }
  self.inheritance_column = "not_sti"

  enum concept: {
    sec: 0, # seconds played/trained
    pts: 1, # points
    dgm: 2, # #two point shots
    dga: 3,
    tgm: 4, # Three point shots
    tga: 5,
    ftm: 6, # Free Throws
    fta: 7,
    drb: 8, # defensive rebounds
    orb: 9, # offensive rebounds
    trb: 10,
    ast: 11,  # assists
    stl: 12,  # steals
    to: 13, # turnovers
    blk: 14,  # blocks
    pfc: 15,  # fouls
    pfr: 16,  # fouls received
    q1: 17, # outing in eaach qwuarter
    q2: 18,
    q3: 19,
    q4: 20,
    q5: 21,
    q6: 22
  }

  # fetch a stat based on event, player & concept
  # ought to be a single one
  def self.fetch(event_id:, player_id:, concept:, stats: nil)
    if stats # we got a stats - typically event.stats 
      res = Stat.by_event(event_id, stats)
      res = Stat.by_player(player_id, res)
      res = Stat.by_concept(concept, res).first
    else
      res = Stat.for_event(event_id).for_player(player_id).for_concept(concept).first
    end
    res
  end

 	# filter stats by player
	def self.by_event(event_id, stats=Stat.real)
		stats.select {|stat| stat.event_id==event_id}
	end

 	# filter stats by player
	def self.by_player(player_id, stats=Stat.for_players)
		stats.select {|stat| stat.player_id==player_id}
	end

 	# filter stats by player
  def self.by_concept(concept, stats=Stat.real)
		stats.select {|stat| stat.concept==concept}
	end

 	# filter stats by quarter
	def self.by_q(q, stats=Stat.for_players)
		stats.select {|stat| stat[:concept]=="q#{q}"}
	end
end

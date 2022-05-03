class Stat < ApplicationRecord
  belongs_to :event
  belongs_to :player  # id==0 => team stat; id==-1 => rival stat
  scope :for_team, -> { where("player_id==0") }
  scope :for_rival, -> { where("player_id==-1") }
  scope :for_players, -> { where("player_id>0") }
  self.inheritance_column = "not_sti"

  enum concept: {
    sec: 0, # seconds played/trained
    pts: 1, # points
    dgm: 2, #
    dga: 3,
    tgm: 4,
    tga: 5,
    ftm: 6,
    fta: 7,
    drb: 8,
    orb: 9,
    trb: 10,
    ast: 11,
    stl: 12,
    to: 13,
    blk: 14,
    pfc: 15,
    pfr: 16
  }
end

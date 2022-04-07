class Event < ApplicationRecord
  belongs_to :team
  belongs_to :location
  scope :training, -> { where("kind = 1") }
  scope :matches, -> { where("kind = 2") }

  enum kind: {
    holiday: 0,
    training: 1,
    match: 2
  }
end

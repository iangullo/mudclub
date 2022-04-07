class Event < ApplicationRecord
  belongs_to :team
  belongs_to :location

  enum kind: {
    holiday: 0,
    training: 1,
    match: 2
  }
end

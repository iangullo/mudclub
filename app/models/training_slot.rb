class TrainingSlot < ApplicationRecord
  belongs_to :season
  belongs_to :location
  belongs_to :team
end

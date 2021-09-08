class Team < ApplicationRecord
  belongs_to :season
  belongs_to :category
  belongs_to :division
end

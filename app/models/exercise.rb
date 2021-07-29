class Exercise < ApplicationRecord
  belongs_to :training_session
  has_one :drill
end

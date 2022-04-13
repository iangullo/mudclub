class Task < ApplicationRecord
  belongs_to :event
  has_one :drill
end

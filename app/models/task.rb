class Task < ApplicationRecord
  belongs_to :event
  has_one :drill

  def to_s
    self.drill.name
  end
end

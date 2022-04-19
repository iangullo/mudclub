class Task < ApplicationRecord
  belongs_to :event
  has_one :drill

  def to_s
    self.drill ? self.drill.name : "<NUEVO>"
  end
end

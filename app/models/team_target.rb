class TeamTarget < ApplicationRecord
  belongs_to :team
  belongs_to :target
  scope :global, -> { where("month=0") }
  scope :monthly, -> (month) { where("month = ?", month) }

  def to_s
    if self.priority
      cad = (self.priority > 0) ? "(" + self.priority.to_s + ") " : ""
    else
      cad = ""
    end
    cad = cad + self.target.concept
  end
end

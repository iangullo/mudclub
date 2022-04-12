class Event < ApplicationRecord
  belongs_to :team
  belongs_to :location
  has_many :event_targets
  has_many :targets, through: :event_targets
  has_many :tasks
  accepts_nested_attributes_for :targets, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :event_targets, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
  scope :trainings, -> { where("kind = 1") }
  scope :matches, -> { where("kind = 2") }

  enum kind: {
    holiday: 0,
    train: 1,
    match: 2
  }

  def start_date
    self.start.to_date
  end

  def hour
		self.start.hour
	end

	def min
		self.start.min
	end

	def hour=(newhour)
		self.start = self.start.change({ hour: newhour })
	end

	def min=(newmin)
		self.start = self.start.change({ min: newmin })
	end

	def ending
		self.start + self.duration.minutes
	end

  def date_string
    cad = self.start.year.to_s
    cad = cad + "/" + two_dig(self.month)
    cad = cad + "/" + two_dig(self.day)
  end

  def time_string
    two_dig(self.hour) + ":" + two_dig(self.min)
  end

  def description
    
  end

  private
  # starting / ending hours as string

  def two_dig(num)
    num.to_s.rjust(2,'0')
  end
end

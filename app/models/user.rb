class User < ApplicationRecord
  has_one :person
  has_one_attached :avatar
  scope :real, -> { where("id>0") }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  def name
    if self.person.nick and self.person.nick.length > 0
      self.person.nick
    else
      self.person.name
    end
  end

  def picture
		self.avatar.attached? ? self.avatar : "user.svg"
	end

  def is_player?
    self.person.player_id > 0
  end

  def is_coach?
    self.person.coach_id > 0
  end

  # get teams assocaited to this user
  def teams
    if self.is_coach?
      Team.joins(:coaches).where(coaches: { id: [self.person.coach_id] })
    elsif self.is_player?
      Team.joins(:players).where(players: { id: [self.person.player_id] })
    else
      nil
    end
  end
end

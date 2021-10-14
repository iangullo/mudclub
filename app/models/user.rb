class User < ApplicationRecord
  has_one :person
  has_one_attached :avatar
  scope :real, -> { where("id>0") }
  enum role: [:user, :player, :coach, :admin]
  after_initialize :set_default_role, :if => :new_record?
  self.inheritance_column = "not_sti"

	# Just list person's full name
	def to_s
		person ? person.to_s : "Nuevo"
	end

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

	# check if associated person exists in database already
	# reloads person if it does
	def is_duplicate?
		if self.person.exists? # check if it exists in database
			if self.person.user_id > 0 # user already exists
				true
			else	# found but mapped to dummy placeholder user
				false
			end
		else	# not found
			false
		end
	end

  def picture
		self.avatar.attached? ? self.avatar : "user.svg"
	end


  #Search field matching
	def self.search(search)
		if search
      search.length>0 ? User.where(person_id: Person.where(["(id > 0) AND (name LIKE ? OR nick like ?)","%#{search}%","%#{search}%"]).order(:birthday)) : User.where(person_id: Person.real.order(:birthday))
		else
      User.none
		end
	end

  def is_player?
    self.person.player_id > 0
  end

  def is_coach?
    self.person.coach_id > 0
  end

  def set_default_role
    self.role ||= :user
  end

  # get teams associated to this user
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

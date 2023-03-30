class UserAction < ApplicationRecord
  belongs_to :user
	scope :logs, -> { where("kind<2") }
	scope :by_user, -> (user_id) { (user_id and user_id.to_i>0) ? where(user_ud: useer_id.to_i) : where("user_id>0").order(:performed_at) }
	scope :by_kind, -> (kind) { (kind and kind.to_i>0) ? where(kind: kind.to_i) : where("kind>1").order(:performed_at) }
	scope :latest, -> { order(performed_at: :desc).first(10) }
	self.inheritance_column = "not_sti"

  enum kind: {
		enter: 0,
		exit: 1,
		created: 2,
		updated: 3,
		deleted: 4,
		imported: 5,
		exported: 6
	}

	# return a standardised string for this user_action datetime
	def date_time
		self.performed_at.localtime.strftime("%Y/%m/%d %H:%M")
	end

	# clear UserAction log - for all users if user is nil
	def self.clear(user=nil)
		actions = user ? UserAction.all : UserAction.by_user(user.id)
		actions.each { |act|
			act.delete
			if user
				user.user_actions.delete(act)
			else
				xuser = User.find(act.user_id)
				xuser.user_actions.delete(act) if xuser
			end
		}
	end
end

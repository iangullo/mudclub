class UserAction < ApplicationRecord
  belongs_to :user
	scope :logs, -> { where("kind<2") }
	scope :by_user, -> (user_id) { (user_id and user_id.to_i>0) ? where(user_ud: useer_id.to_i) : where("user_id>0").order(:performed_at) }
	scope :by_kind, -> (kind) { (kind and kind.to_i>0) ? where(kind: kind.to_i) : where("kind>1").order(:performed_at) }

  enum kind: {
		enter: 0,
		exit: 1,
		created: 2,
		updated: 3,
		deleted: 4,
		imported: 5,
		exported: 6
	}
end

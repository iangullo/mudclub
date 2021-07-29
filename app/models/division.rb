class Division < ApplicationRecord
	scope :real, -> { where("id>0") }
end

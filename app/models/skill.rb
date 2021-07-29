class Skill < ApplicationRecord
	has_and_belongs_to_many :drills
#	accepts_nested_attributes_for :drills, reject_if: :all_blank
end

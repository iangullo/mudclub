class EventTarget < ApplicationRecord
  belongs_to :event
  belongs_to :target
  accepts_nested_attributes_for :target, reject_if: :all_blank
end

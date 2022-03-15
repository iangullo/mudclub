class Target < ApplicationRecord
  has_many :team_targets
  has_many :targets, through: :team_targets

  enum aspect: {
    general: 0,
    individual: 1,
    collective: 2
  }
  enum focus: {
    physical: 0,
    offense: 1,
    defense: 2
  }
end

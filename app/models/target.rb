class Target < ApplicationRecord
  has_many :team_targets
  has_many :teams, through: :team_targets
  has_many :drill_targets
  has_many :drills, through: :drill_targets
  self.inheritance_column = "not_sti"

  enum aspect: {
    general: 0,
    individual: 1,
    collective: 2,
    strategy: 3
  }
  enum focus: {
    physical: 0,
    offense: 1,
    defense: 2
  }

  def self.aspects
    res = Array.new
    res << ["General",0]
    res << ["Técnica",1]
    res << ["Táctica",2]
#    res << ["Estrategia",3]
  end

  def self.kinds
    res = Array.new
    res << ["Físico",0]
    res << ["Ataque",1]
    res << ["Defensa",2]
  end

  #Search target matching. returns either nil or a Target
	def self.search(concept, focus=nil, aspect=nil)
    res = nil
		if concept
			if concept.length > 0
        res = Target.where("unaccent(concept) ILIKE unaccent(?)","%#{concept}%")
        res = focus ? res.where(focus: focus.to_i) : res
        res = aspect ? res.where(aspect: aspect.to_i) : res
      end
      res = res.first
		end
    return res
	end
end

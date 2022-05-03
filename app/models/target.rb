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
    res << [I18n.t(:h_general), 0]
    res << [I18n.t(:l_tec), 1]
    res << [I18n.t(:l_tac), 2]
#    res << ["Estrategia",3]
  end

  def self.kinds
    res = Array.new
    res << [I18n.t(:l_fit), 0]
    res << [I18n.t(:l_off), 1]
    res << [I18n.t(:l_def), ,2]
  end

  #Search target matching. returns either nil or a Target
	def self.search(id, concept, focus=nil, aspect=nil)
    res = id ? Target.find(id.to_i) : nil
		if res==nil and concept
			if concept.length > 0
        res = Target.where("unaccent(concept) ILIKE unaccent(?)","%#{concept}%")
        res = focus ? res.where(focus: focus.length==1 ? focus.to_i : focus.to_sym) : res
        res = aspect ? res.where(aspect: aspect.length==1 ? aspect.to_i : aspect.to_sym) : res
      end
      res = res.first
		end
    return res
	end
end

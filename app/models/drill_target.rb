class DrillTarget < ApplicationRecord
  belongs_to :target
  belongs_to :drill
  accepts_nested_attributes_for :target, reject_if: :all_blank
  self.inheritance_column = "not_sti"

  def to_s
    if self.priority
      cad = (self.priority > 0) ? "(" + self.priority.to_s + ") " : ""
    else
      cad = ""
    end
    cad = cad + self.target.concept
  end

  # Takes the input received from target_form (f_object)
  # and either reads or creates a matching drill_target
  def self.fetch(f_object)
    res = f_object[:id] ? DrillTarget.find(f_object[:id]) : DrillTarget.new
    t   = f_object[:target_attributes]
    tgt = Target.search(t[:concept], t[:focus], t[:aspect])
    tgt = Target.new unless tgt # ensure we have a target
    tgt.concept  = t[:concept]      # accept concept edition
    tgt.focus    = t[:focus].to_i   # accept focus edition
    tgt.aspect   = t[:aspect].to_i  # accept aspect edition
    res.target   = tgt
    res.priority = f_object[:priority]
    return res
  end
end

class TeamTarget < ApplicationRecord
  belongs_to :team
  belongs_to :target
  scope :global, -> { where(month: 0) }
  scope :plan, -> { where("month>0") }
  scope :monthly, -> (month) { where(month: month) }
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
    res = f_object[:id] ? TeamTarget.find(f_object[:id]) : TeamTarget.new
    t   = f_object[:target_attributes]
    tgt = Target.search(t[:target_id], t[:concept], t[:focus], t[:aspect])
    tgt = Target.new unless tgt # ensure we have a target
    tgt.concept  = t[:concept]        # accept concept edition
    tgt.focus    = t[:focus].length==1 ? t[:focus].to_i : t[:focus].to_sym  # accept focus edition
    tgt.aspect   = t[:aspect].length==1 ? t[:aspect].to_i : t[:aspect].to_sym  # accept aspect edition
    tgt.save unless tgt.persisted?
    res.target   = tgt
    res.priority = f_object[:priority]
    res.month    = f_object[:month]
    return res
  end
end

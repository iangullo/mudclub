class Task < ApplicationRecord
  belongs_to :event
  belongs_to :drill
  self.inheritance_column = "not_sti"

  def to_s
    self.drill ? self.drill.nice_string : I18n.t(:d_drill)
  end

  # Takes the input received from add_task (f_object)
  # and either reads or creates a matching drill_target
  def self.fetch(f_object)
    res = f_object[:id] ? Task.find(f_object[:id].to_i) : Task.new
    res.order    = f_object[:order].to_i
    res.drill_id = f_object[:drill_id].to_i
    res.duration = f_object[:duration].to_i
    return res
  end
end

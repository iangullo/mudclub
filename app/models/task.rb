class Task < ApplicationRecord
	belongs_to :event
	belongs_to :drill
	has_rich_text :remarks
	self.inheritance_column = "not_sti"

	def to_s
		self.drill ? self.drill.nice_string : I18n.t("drill.default")
	end

	def s_dur
		self.duration.to_s + "\'"
	end

	def headstring
		"#{self.order.to_s.rjust(2, "0")} - #{self.to_s} (#{self.s_dur})"
	end

	# Takes the input received from add_task (f_object)
	# and either reads or creates a matching drill_target
	def self.fetch(f_object)
		res = f_object[:id] ? Task.find(f_object[:id].to_i) : Task.new
		res.order    = f_object[:order].to_i
		res.drill_id = f_object[:drill_id].to_i
		res.duration = f_object[:duration].to_i
		res.remarks  = f_object[:remarks]
		return res
	end
end

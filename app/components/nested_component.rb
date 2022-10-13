# frozen_string_literal: true

class NestedComponent < ApplicationComponent
	def initialize(model:, key:, form:, child:, row:)
		@model   = model
		@form    = form
		@child   = child
		@key     = key
#    @fields  = nested_form_fields(fields)
		@row     = row
		@btn_add = ButtonComponent.new(button: {kind: "add-nested"})
	end

	# add remove button at end of row fields
	def nested_form_fields(fields)
		btn_del =  {kind: "remove"}
		fields.each {|item|
			item << {kind: "hidden", key: :_destroy}
			item << btn_del
		}
		fields
	end
end

# frozen_string_literal: true

class NestedComponent < ApplicationComponent
  def intialize(form:,key:,fields:)
binding.break
    @form    = form
    @key     = key
    @fields  = nested_form_fields(fields)
    @btn_add = ButtonComponent.new(button: {kind: "add-nested", data: {turbo_frame: form.field_id(@key)}, name: "add_#{@key.to_s.chop}"})
  end

  # add remove button at end of row fields
  def nested_form_fields(fields)
    btn_del =  {kind: "remove", data: {turbo_frame: form.field_id(@key)}, name: "del_#{@key.to_s.chop}"}
    fields.each {|item|
      item << {kind: "hidden", key: :_destroy}
      item << btn_del
    }
    fields
  end
end

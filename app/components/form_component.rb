# frozen_string_literal: true
# items in fields specify:
# => kind: type of field to render
# => value:
class FormComponent < ApplicationComponent
  def initialize(form: , fields:)
    @form    = form
    @content = parse(fields)
  end

  def parse(fields)
    res = Array.new
    fields.each do |row|
      res << [] # new row n header
      row.each do |item|
        case item[:kind]
        when "icon"
          item[:align] = "right"
          item[:class] = "align-middle"
          item[:size]  = "25x25" unless item[:size]
        when "label", "label-checkbox"
          item[:align] = "left"
          item[:class] = "align-top font-semibold"
        when "text-area", "icon-number-box"
          item[:align] = "right"
          item[:class] = "inline-flex"
        when "icon-label", "icon-text-box", "icon-number-box"
          item[:align] = "right"
          item[:class] = "inline-flex"
        else
          item[:align] = "left"
        end
        res.last << item
      end
    end
    res
  end
end

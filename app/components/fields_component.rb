# frozen_string_literal: true

# Arguments received:
# => icon: identifier of related icon taking 2 rows
# => content: array of 1..3 rows containing hashes :kind, :value, etc.
# valid content item kinds:
# => "icon": :value (name of icon file in assets)
# => "header-icon": :value (name of icon file in assets)
# => "title": :value (bold text of title)
# => "icon-value": :icon (name of icon file), :value (added text)
# => "label": :value (semibold text string)
# => "select-box": :collection, :value (form, select)
# => "date-box": :value (date_field)
# => "string": :value (regular text string)
# => "text-box": :key (field name), :value (text_field)
# => "icon-text-box": :icon (name of icon file) + text-box attributes
# => "number-box": :key (field name), :value (number_field)
# => "icon-number-box": :icon (name of icon file) + number-box attributes
# => "text-search": :url (search_in), :value
class FieldsComponent < ApplicationComponent
  def initialize(fields:, form: nil)
    @fields = parse(fields)
    @form   = form
  end

  private
  def parse(fields)
    res = Array.new
    fields.each do |row|
      res << [] # new row n header
      row.each do |item|
        case item[:kind]
        when "icon"
          item[:align] = "right" unless item[:align]
          item[:class] = "align-middle" unless item[:class]
          item[:size]  = "25x25" unless item[:size]
        when "header-icon"
          item[:align] = "center"
          item[:class] = "align-top"
          item[:size]  = "50x50" unless item[:size]
          item[:rows]  = 2 unless item[:rows]
        when "title"
          item[:align] = "left"
          item[:class] = "align-top font-bold text-yellow-600"
        when "subtitle"
          item[:align] = "left"
          item[:class] = "align-top font-bold"
        when "label", "label-checkbox"
          item[:align] = "left" unless item[:align]
          item[:class] = "inline-flex align-top font-semibold"
        when "location"
          item[:align] = "left" unless item[:align]
          item[:class] = "inline-flex align-top font-semibold"
          item[:i_class] = "rounded-md hover:bg-blue-100"
        when "string"
          item[:align] = "left" unless item[:align]
          item[:class] = "align-top"
        when "text-box", "text-area"
          item[:align] = "left" unless item[:align]
          item[:size]  = 16 unless item[:size]
          item[:lines]  = 1 unless item[:lines]
          item[:i_class] = "rounded border shadow-inner"
        when "icon-label"
          item[:align] = "left" unless item[:align]
          item[:size]  = "16" unless item[:size]
          item[:class] = "align-top inline-flex"
        when "search-text", "search-select", "search-collection"
          item[:align] = "left" unless item[:align]
          item[:class] = "inline-flex rounded border"
          item[:size]  = 16 unless item[:size]
          item[:i_class] = "rounded border shadow-inner"
        when "link-button"
          item[:align]   = "center"
          item[:size]    = "50x50" unless item[:size]
          if item[:modal]
            item[:i_class] = "rounded-md hover:bg-yellow-200"
          else
            item[:i_class] = "rounded-md hover:bg-blue-100"
          end
        when "location"
          item[:i_class] = "rounded hover:bg-blue-100"
        when "gap"
          item[:size]  = 4 unless item[:size]
        else
          item[:align] = "left" unless item[:align]
          item[:i_class] = "rounded border shadow-inner" unless item[:kind]=="gap"
        end
        res.last << item
      end
    end
    res
  end

  def tag_mod(item)
    cad = ""
    cad = (cad + " rowspan=\"#{item[:rows].to_s}\"") if item[:rows]
    cad = (cad + " colspan=\"#{item[:cols].to_s}\"") if item[:cols]
    cad = (cad + " align=\"#{item[:align]}\"") if item[:align]
    cad = (cad + " class=\"#{item[:class]}\"") if item[:class]
  end
end

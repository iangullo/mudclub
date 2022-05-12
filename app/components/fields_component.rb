# frozen_string_literal: true

# ViewComponent to render rows of fields as table cells in a view
# managing different kinds of content for each field:
# => "icon": :value (name of icon file in assets)
# => "header-icon": :value (name of icon file in assets)
# => "title": :value (bold text of title in orange colour)
# => "subtitle": :value (bold text of title)
# => "label": :value (semibold text string)
# => "string": :value (regular text string)
# => "icon-label": :icon (name of icon file), :value (added text)
# => "label-checkbox": :key (attribute of checkbox), :value (added text)
# => "text-box": :key (field name), :value (text_field), :size (box size)
# => "email-box": :key (field name), :value (email_field), :size (box size)
# => "password-box": :key (field name), :value (password_field)
# => "text-area": :key (field name), :value (text_field), :size (box size), lines: number of lines
# => "rich-text-area": :key (field name)
# => "number-box": :key (field name), :value (number_field), size:
# => "date-box": :key (field name), :value (date_field), :s_year (start_year)
# => "select-box": :key (field name), :options (array of valid options), :value (form, select)
# => "select-collection": :key (field name), :collection, :value (form, select)
# => "search-text": :url (search_in), :value
# => "search-select": :key (search field), :url (search_in), :collection, :value
# => "location": :icon (optional), :url (gmaps_url), :name (name to display)
# => "link_button": :icon (optional), :url (link_to_url), :label (label to display), turbo: (pass turbo frame?)
# => "modal-add": :url (link_to_url)
# => "gap": :size (count of &nbsp; to separate content)
class FieldsComponent < ApplicationComponent
  def initialize(fields:, form: nil)
    @fields = parse(fields)
    @form   = form
  end

  def render?
    @fields.present?
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
          item[:size]  = "25x25" unless item[:size]
          item[:class] = "align-top inline-flex"
        when "search-text", "search-select", "search-collection"
          item[:align] = "left" unless item[:align]
          item[:class] = "inline-flex rounded border"
          item[:size]  = 16 unless item[:size]
          item[:i_class] = "rounded border shadow-inner"
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
end

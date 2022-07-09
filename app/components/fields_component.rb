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
# => "time-box": :hour & :min (field names)
# => "select-box": :key (field name), :options (array of valid options), :value (form, select)
# => "select-collection": :key (field name), :collection, :value (form, select)
# => "select-file": :key (field name), :icon, :label, :value (form, select)
# => "search-text": :url (search_in), :value
# => "search-select": :key (search field), :url (search_in), :options, :value
# => "search-collection": :key (search field), :url (search_in), :options, :value
# => "search-combo": :key (search field), :url (search_in), :options
# => "location": :icon (optional), :url (gmaps_url), :name (name to display)
# => "link": :icon (optional), :url (link_to_url), :label (label to display), turbo: (pass turbo frame?)
# => "jump": :icon (optional), :url (link_to_url in the site), :label (label to display), turbo: (pass turbo frame?)
# => "hidden": :a hidden link for the form
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
          item[:class] = item[:class] ? item[:class] + " align-middle" : "align-middle"
          item[:size]  = "25x25" unless item[:size]
        when "header-icon"
          item[:align] = "center"
          item[:class] = item[:class] ? item[:class] + " align-top" : "align-top"
          item[:size]  = "50x50" unless item[:size]
          item[:rows]  = 2 unless item[:rows]
        when "title"
          item[:class] = "align-top font-bold text-yellow-600"
        when "subtitle"
          item[:class] = "align-top font-bold"
        when "label", "label-checkbox"
          item[:class]   = item[:class] ? item[:class] + " inline-flex align-top font-semibold" : " inline-flex align-top font-semibold"
          item[:i_class] = "rounded bg-gray-200 text-blue-700"
        when "link", "select-file"
          item[:class]   = item[:class] ? item[:class] : " inline-flex align-middle p-0 text-sm"
          item[:size]    = "20x20" unless item[:size]
          item[:i_class] = "rounded text-sm m-0 text-gray-500 py-0 px-0" if item[:kind]=="select-file"
        when "location"
          item[:class]   = "inline-flex align-top font-semibold"
          item[:i_class] = "rounded-md hover:bg-blue-100"
        when "string"
          item[:class] = "align-top"
        when /^(search-.+)$/
          item[:align]   = "left" unless item[:align]
          item[:size]    = 16 unless item[:size]
          item[:lines]   = 1 unless item[:lines]
          item[:i_class] = "rounded py-0 px-1 shadow-inner border-gray-200 bg-gray-50 text-sm focus:ring-blue-700 focus:border-blue-700"
          item[:class]   = "inline-flex rounded border"
          item[:fields]  = [{kind: item[:kind], key: item[:key].to_sym, options: item[:options], value: item[:value]}] unless item[:kind] == "search-combo"
          item[:kind]    = "search-combo"
        when "icon-label"
          item[:size]  = "25x25" unless item[:size]
          item[:class] = "align-top inline-flex"
        when "gap"
          item[:size]  = 4 unless item[:size]
        when "side-cell"
          item[:align] = "right" unless item[:align]
          item[:class] = "align-center font-semibold text-indigo-900"
        when "top-cell"
          item[:class] = "font-semibold bg-indigo-900 text-gray-300 align-center border px py"
        when "lines"
          item[:class] = "align-top py-0 px-1 border px py" unless item[:class]
        when /^(select-.+|.+-box|.+-area)$/
          item[:i_class] = "rounded py-0 px-1 shadow-inner border-gray-200 bg-gray-50 focus:ring-blue-700 focus:border-blue-700"
          if item[:kind]=="number-box"
            item[:i_class] = item[:i_class] + " text-right"
            item[:min]     = 0 unless item[:min]
            item[:max]     = 99 unless item[:max]
            item[:step]    = 1 unless item[:step]
        when "accordion"
          item[:h_class] = "font-semibold text-left text-indigo-900"
          item[:t_class] = "font-semibold text-right text-indigo-900"
          item[:i_class] = "flex justify-between items-center p-1 w-full text-gray-700 bg-gray-50 font-medium text-left rounded-md hover:bg-indigo-100 focus:text-gray-200 focus:bg-indigo-900"
          i = 1
          item[:objects].each { |obj|
            obj[:head_id] = "accordion-collapse-heading-" + i.to_s
            obj[:body_id] = "accordion-collapse-body-" + i.to_s
            i = i +1
          }
        else
          item[:i_class] = "rounded p-0" unless item[:kind]=="gap"
        end
        item[:align] = "left" unless item[:align]
        item[:cell]  = tablecell_tag(item)
        res.last << item
      end
    end
    res
  end
end

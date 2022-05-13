# frozen_string_literal: true

class GridComponent < ApplicationComponent
  # head items:
  # => kind: :normal | :inverse | :gap | :button
  # => value: associated text
  # => class: optional (unrequired?)
  # row items: have links in them (per row)
  def initialize(g_head:, g_rows: nil)
    @g_head = parse_head(g_head)
    @g_rows = parse_rows(g_rows)
  end

  private
    # parse header definition to set correct objects
    def parse_head(g_head)
      res = Array.new
      g_head.each { |item|
        case item[:kind]
        when "normal"
          item[:class] = "font-semibold border px py"
        when "inverse"
          item[:class] = "font-semibold bg-white text-indigo-900 border px py"
        when "gap"
          item[:value] = "&nbsp;"
        when "add", "add-event", "dropdown"
          item[:class] = "bg-white"
        end
        item[:align] = "left" unless item[:align]
        item[:cell]  = tablecell_tag(item, :th)
        res << item
      }
      res
    end

    # parse row definitions to set correct objects
    # each row links to a url - buttons to specific url
    def parse_rows(g_rows)
      g_rows.each { |row|
        row[:items].each { |item|
          case item[:kind]
          when "normal", "lines", "icon", "location"
            item[:class] = "border px py"
          when "add", "add-event", "delete", "dropdown"
            item[:class] = "bg-white"
          when "bottom"
            item[:align] = "center" unless item[:align]
            item[:class] = "text-indigo-900 font-semibold"
          end
          item[:align] = "left" unless item[:align]
          item[:cell]  = tablecell_tag(item)
        }
      }
      g_rows
    end
end

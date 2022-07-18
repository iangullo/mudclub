# frozen_string_literal: true

class GridComponent < ApplicationComponent
  # grid has two components:
  # title items:
  # => kind: :normal | :inverse | :gap | :button
  # => value: associated text
  # => class: optional (unrequired?)
  # row items: have links in them (per row)
  def initialize(grid:)
    @title = parse_title(grid[:title])
    @rows  = parse_rows(grid[:rows])
    if grid[:track]
      @s_url  = grid[:track][:s_url]
      @s_filt = grid[:track][:s_filter]
    end
  end

  def update(rows:)
    @rows  = parse_rows(rows)
  end

  def build_order_link(column:, label:)
    if column == session.dig(@s_filt, 'column')
      link_to(label, @s_url + "?column=#{column}&direction=#{next_direction}")
    else
      link_to(label, @s_url + "?column=#{column}&direction=asc")
    end
  end

  def sort_indicator
    tag.span(class: "sort sort-#{session[@s_filt]['direction']}")
  end

  private
    # parse header definition to set correct objects
    def parse_title(title)
      res = Array.new
      title.each { |item|
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
    def parse_rows(rows)
      rows.each { |row|
        row[:items].each { |item|
          case item[:kind]
          when "normal", "lines", "icon", "location"
            item[:class] = "border px py"
          when "add", "add-event", "delete", "dropdown"
            item[:class] = "bg-white"
          when "bottom"
            item[:align] = "center" unless item[:align]
            item[:class] = "text-indigo-900 font-semibold"
          when "percentage"
            item[:align] = "center" unless item[:align]
            item[:class] = "font-semibold border px py "
            if item[:value] # not nil
              case item[:value]
              when 0..25
                item[:class] = item[:class] + "text-red-900"
              when 26..50
                item[:class] = item[:class] + "text-yellow-700"
              when 51..75
                item[:class] = item[:class] + "text-gray-700"
              when 76..100
                item[:class] = item[:class] + "text-green-900"
              end
              item[:value] = number_to_percentage(item[:value], precision: 0)
            else
              item[:value] = ""
            end
          end
          item[:align] = "left" unless item[:align]
          item[:cell]  = tablecell_tag(item)
        }
      }
      rows
    end

    def next_direction
      session[@s_filt]['direction'] == 'asc' ? 'desc' : 'asc'
    end
end

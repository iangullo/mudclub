# frozen_string_literal: true

class DropdownComponent < ApplicationComponent
  def initialize(button:)
    @button = parse(button)
  end

  def render?
    @button.present?
  end

  private
  # determine class of item depending on kind
  def parse(button)
    @button = button
    set_icon
    set_iclass
    case @button[:kind]
    when "add"
      @button[:d_class] = "text-left text-blue-900 bg-gray-100 shadow rounded border overflow-hidden no-underline"
      @button[:o_class] = "hover:bg-blue-700 hover:text-white whitespace-nowrap no-underline block"
    when "menu"
      @button[:d_class] = "bg-blue-900 shadow rounded border overflow-hidden"
      @button[:o_class] = "no-underline block pl-3 pr-3 py-3 hover:bg-blue-700 hover:text-white whitespace-nowrap"
    end
    @button
  end

  # determine class of item depending on kind
  def set_icon
    case @button[:kind]
    when "add"
      @button[:icon]    = "add.svg"
    when "menu"
      @button[:icon]    = nil
    end
  end

  # set the i_class for the button div
  def set_iclass
    case @button[:kind]
    when "add"
      @button[:i_class] = "max-h-6 min-h-4 align-center rounded-lg hover:bg-green-200"
    when "menu"
      @button[:i_class] = "bg-blue-900 shadow rounded border overflow-hidden"
    end
  end
end

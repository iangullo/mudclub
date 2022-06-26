# frozen_string_literal: true

# Dropdown buttons are specific for muli-add and menu buttons - have an :options array with :url,:icon:label
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
    set_name
    set_bclass
    case @button[:kind]
    when "add"
      @button[:d_class] = "hidden text-left text-blue-900 bg-gray-100 shadow rounded border overflow-hidden no-underline"
      @button[:o_class] = "hover:bg-blue-700 hover:text-white whitespace-nowrap no-underline block"
    when "menu"
      @button[:d_class] = "hidden bg-blue-900 shadow rounded border overflow-hidden"
      @button[:o_class] = "no-underline block m-0 pl-2 pr-2 py-2 hover:bg-blue-700 hover:text-white whitespace-nowrap"
    end
    @button
  end

  # determine class of item depending on kind
  def set_name
    @button[:id]   = "#{@button[:name]}Default"
    @button[:icon] = "add.svg" if @button[:name]=~/^(add.*)$/
  end

  # set the i_class for the button div
  def set_bclass
    if @button[:kind] =~ /^(add.*)$/
      @button[:b_class] = "max-h-6 min-h-4 align-center rounded-lg hover:bg-green-200 focus:bg-green-200"
    else
      @button[:b_class] = @button[:class] ? @button[:class] : "hover:bg-blue-700 hover:text-white focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200 whitespace-nowrap shadow rounded ml-2 px-2 py-2 rounded-md font-semibold"
    end
  end
end

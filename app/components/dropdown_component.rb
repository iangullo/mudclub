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
    when "add","link"
      @button[:d_class] = "hidden rounded-md shadow border-2 border-gray-300 bg-gray-100 text-gray-500 text-left font-semibold overflow-hidden no-underline"
      @button[:o_class] = "hover:bg-blue-700 hover:text-white whitespace-nowrap no-underline block m-0 pl-1 pr-1"
    when "menu"
      @button[:d_class] = "hidden rounded-md shadow bg-blue-900 overflow-hidden"
      @button[:o_class] = "hover:bg-blue-700 hover:text-white whitespace-nowrap no-underline block m-0 pl-2 pr-2 py-2"
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
    case @button[:kind]
    when /^(add.*)$/
      @button[:b_class] = "max-h-6 min-h-4 align-center rounded-md hover:bg-green-200 focus:bg-green-200 focus:ring-2 focus:ring-green-500"
    when "link"
      @button[:b_class] = @button[:class] ? @button[:class] : "inline-flex align-center rounded-md shadow bg-gray-100 hover:bg-gray-300 focus:ring-gray-300 focus:ring-2 focus:border-gray-300 font-semibold whitespace-nowrap px-1 py-1 m-1"
    when "menu"
      @button[:b_class] = @button[:class] ? @button[:class] : "hover:bg-blue-700 hover:text-white focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200 whitespace-nowrap shadow rounded ml-2 px-2 py-2 rounded-md font-semibold"
    end
  end
end

# frozen_string_literal: true
# Create buttons to be used in views
# button is hash with following fields:
# (kind: , max_h: 6, icon: nil, label: nil, url: nil, turbo: nil)
# kinds of button:
# => "add": new item button
# => "add-nested": new nested-item
# => "close": form close
# => "delete": delete item
# => "edit": edit link_to
# => "export": export data to excel
# => "import": import data from excel
# => "remove": remove item from nested form
# => "save": save form
class ButtonComponent < ApplicationComponent
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
    set_bclass
    case @button[:kind]
    when "add", "add-nested", "export", "import", "save"
      @button[:d_class] = "rounded-lg inline-flex hover:bg-green-200 text-green-700 font-bold align-middle"
    when "edit"
      @button[:d_class] = "rounded-lg inline-flex hover:bg-yellow-200 text-yellow-700 font-bold align-middle"
    when "close", "delete", "remove"
      @button[:d_class] = "rounded-lg inline-flex hover:bg-red-200 text-red-700 font-bold align-middle"
    when "jump"
      d_class           = "rounded-lg hover:bg-blue-100 align-middle"
      @button[:d_class] = @button[:d_class] ? @button[:d_class] + " #{d_class}" : d_class + " text-sm align-middle"
    when "link"
      @button[:d_class] = "rounded-lg inline-flex hover:bg-yellow-200 text-sm align-middle"
    when "location"
      @button[:tab]     = true
      @button[:d_class] = "rounded-lg hover:bg-blue-100 inline-flex align-middle"
      @button[:d_class] = @button[:d_class] + " align-middle text-sm" if @button[:icon]
    end
    @button[:align]   = "center" unless @button[:align]
    @button[:replace] = true if @button[:kind] =~ /^(edit|close|save)$/
    @button
  end

  # determine class of item depending on kind
  def set_icon
    case @button[:kind]
    when "add", "add-nested"
      @button[:icon]    = "add.svg"
    when "close"
      @button[:icon]    = "close.svg"
    when "delete"
      @button[:icon]    = "delete.svg"
      @button[:method]  = "delete"
      @button[:confirm] = I18n.t(:q_del) + " \'#{@button[:name]}\'?"
    when "edit"
      @button[:icon]    = "edit.svg"
    when "export"
      @button[:icon]    = "export.svg"
    when "import"
      @button[:icon]    = "import.svg"
      @button[:confirm] = I18n.t(:q_import)
    when "jump"
      @button[:size]    = "50x50" unless @button[:size]
    when "remove"
      @button[:icon]    = "remove.svg"
    when "save"
      @button[:icon]    = "save.svg"
      @button[:confirm] = I18n.t(:q_save_chng)
    end
    @button[:size] = "25x25" unless @button[:size]
  end

  # set the @button class depending on button type
  def set_bclass
    case @button[:kind]
    when "add-nested"
      @button[:action]  = "nested-form#add"
    when "remove"
      @button[:action]  = "nested-form#remove"
    when "import", "save"
      @button[:b_class] = "save-button inline-flex"
    when "close"
      @button[:action]  = "click->extended-modal#close"
    end
    @button[:b_class] = "#{@button[:kind]}-button inline-flex" unless @button[:b_class]
  end

  # set the i_class for the button div
  def set_iclass
    case @button[:kind]
    when "add", "delete", "location", "link"
      @button[:i_class] = "max-h-6 min-h-4 align-middle"
    when "add-nested", "remove"
      @button[:i_class] = "max-h-5 min-h-4 align-middle"
    when  "close", "cancel", "save", "export", "import", "edit"
      @button[:i_class] = "max-h-7 min-h-5 align-middle"
    end
  end
end

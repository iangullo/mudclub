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
      @button[:d_class] = "rounded-lg hover:bg-blue-100 text-sm align-middle"
    when "location"
      @button[:tab]     = true
      @button[:d_class] = "rounded-lg hover:bg-blue-100 inline-flex align-middle"
      @button[:d_class] = @button[:d_class] + " align-center text-sm" if @button[:icon]
    end
    @button[:align] = "center" unless @button[:align]
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
      @button[:confirm] = I18n.t(:q_del) + " \'#{@button[:name]}\'?"
    when "edit"
      @button[:icon]    = "edit.svg"
    when "export"
      @button[:icon]    = "export.svg"
    when "import"
      @button[:icon]    = "import.svg"
      @button[:confirm] = I18n.t(:q_import)
    when "jump"
      @button[:size]    = "50x50"
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
      @button[:action]  = "nested-form#add"
    when "remove"
      @button[:action]  = "nested-form#remove"
    when "import", "save"
      @button[:b_class] = "save-button inline-flex"
    when "close"
      @button[:b_class] = "close-button inline-flex"
      @button[:action]  = "click->extended-modal#close"
    else
      @button[:b_class] = "#{@button[:kind]}-button"
    end
  end

  # set the i_class for the button div
  def set_iclass
    case @button[:kind]
    when "add", "delete", "location"
      @button[:i_class] = "max-h-6 min-h-4 align-center"
    when "add-nested", "remove"
      @button[:i_class] = "max-h-5 min-h-4 align-center"
    when  "cancel", "save", "export", "import"
      @button[:i_class] = "max-h-7 min-h-5 align-center"
    end
  end
end

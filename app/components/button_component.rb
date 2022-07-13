# frozen_string_literal: true
# Create buttons to be used in views
# button is hash with following fields:
# (kind: , max_h: 6, icon: nil, label: nil, url: nil, turbo: nil)
# kinds of button:
# => "add": new item button
# => "add-nested": new nested-item
# => "cancel": non-modal form cancel
# => "close": modal close
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
    set_data
    b_colour = set_colour
    @button[:d_class] = "inline-flex align-middle" unless @button[:d_class]
    case @button[:kind]
    when "jump"
      @button[:d_class] = @button[:d_class] + " m-1 text-sm"
    when "location"
      @button[:tab]     = true
      @button[:d_class] = @button[:d_class] + " text-sm" if @button[:icon]
    when "save", "edit", "menu", "login", "cancel", "close"
      b_colour = b_colour + " shadow font-bold"
      @button[:d_class] = @button[:d_class] + " shadow"
    else
      @button[:d_class] = @button[:d_class] + " font-semibold"
    end
    @button[:align]   = "center" unless @button[:align]
    @button[:replace] = true if @button[:kind] =~ /^(cancel|close|save)$/
    @button[:d_class] = @button[:d_class] + (b_colour ?  b_colour : "")
    @button
  end

  # determine class of item depending on kind
  def set_icon
    case @button[:kind]
    when "add", "add-nested"
      @button[:icon]    = "add.svg"
    when "cancel"
      @button[:icon]    = "close.svg"
      @button[:turbo]   = "_top"
    when "close"
      @button[:icon]    = "close.svg"
    when "delete"
      @button[:turbo]   = "_top"
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
      @button[:size]    = "50x50" unless @button[:size]
      @button[:turbo]   = "_top" unless @button[:turbo]
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
    b_start        = @button[:b_class] ? "#{@button[:kind]}-btn " + @button[:b_class] : "#{@button[:kind]}-btn"
    @button[:name] = @button[:kind]
    case @button[:kind]
    when "remove"
      @button[:action] = "nested-form#remove"
    when "add", "add-nested"
      @button[:action] = "nested-form#add" if @button[:kind]=="add-nested"
    when "close"
      @button[:action] = "turbo-modal#hideModal"
      b_start = b_start + " font-bold"
    when "cancel", "save", "import", "export", "menu", "login"
      b_start = b_start + " font-bold"
    end
    @button[:type]    = "submit" if @button[:kind] =~ /^(save|import)$/
    @button[:b_class] = b_start + (@button[:kind]!= "jump" ? " m-1 inline-flex align-middle" : "")
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

  # set button higlight (if needed)
  def set_colour
    res = " rounded-lg "
    case @button[:kind]
    when "delete", "remove", "close", "cancel"
      colour = "red"
    when "edit", "attach"
      colour = "yellow"
    when "save", "import", "export", "add", "add-nested"
      colour = "green"
    when "jump", "link"
      light = "blue-100"
    when "menu"
      wait  = "blue-900"
      light = "blue-700"
      text  = "gray-200"
      high  = "white"
    end
    if colour
      res = res + "hover:bg-#{colour}-200 text-#{colour}-700"
    elsif wait
      res = res + "bg-#{wait} text-#{text} hover:bg-#{light} hover: text-#{high}"
    else
      res = res + "hover:bg-#{light}"
    end
    res
  end

  # set the turbo data frame if required
  def set_data
    res = @button[:turbo] ? {turbo_frame: @button[:turbo]} : {}
    res[:turbo_confirm] = @button[:confirm] if @button[:confirm]
    res[:turbo_method]  = "delete".to_sym if @button[:kind]=="delete"
    res[:action]        = @button[:action] if @button[:action]
    @button[:data]      = res unless res.empty?
  end
end

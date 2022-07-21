# frozen_string_literal: true

class SubmitComponent < ApplicationComponent
  def initialize(close: "close", submit: nil, close_return: nil, frame: nil)
    case close
    when "close"
      @close = {kind: "close", label: (submit=="save" ? I18n.t("action.cancel"): I18n.t("action.close")), url: close_return}
    when "cancel"
      @close = {kind: "cancel", label: I18n.t("action.cancel"), url: close_return, frame:}
    when "back"
      @close = {kind: "back", label: I18n.t("action.return"), url: close_return}
    end
    if submit == "save" # save button
      @submit = {kind: "save", label: I18n.t("action.save")}
    elsif submit # edit button with link in "submit"
      @submit = {kind: "edit", label: I18n.t("action.edit"), url: submit, frame:}
    end
  end
end

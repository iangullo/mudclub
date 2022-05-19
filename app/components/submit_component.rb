# frozen_string_literal: true

class SubmitComponent < ApplicationComponent
  def initialize(submit: nil)
    @close = {kind: "close", label: I18n.t(:m_close)}
    if submit == "save" # save button
      @submit = {kind: "save", label: I18n.t(:m_save)}
    elsif submit # edit button with link in "submit"
      @submit = {kind: "edit", label: I18n.t(:m_edit), url: submit}
    end
  end
end

# frozen_string_literal: true

class SubmitComponent < ApplicationComponent
  def initialize(close: true, modal: true, submit: nil, close_return: nil, turbo: nil)
    if close
      if modal
        @close = {kind: "close", label: I18n.t(:m_close), url: close_return}
      else
        @close = {kind: "cancel", label: I18n.t(:m_cancel), url: close_return, turbo: turbo}
      end
    end
    if submit == "save" # save button
      @submit = {kind: "save", label: I18n.t(:m_save)}
    elsif submit # edit button with link in "submit"
      @submit = {kind: "edit", label: I18n.t(:m_edit), url: submit, turbo: turbo}
    end
  end
end

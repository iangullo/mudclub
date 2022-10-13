# frozen_string_literal: true
# => :submit is either edit or save button (optional)
include Turbo::FramesHelper

class ModalComponent < ApplicationComponent
	def initialize(simple: nil)
		@close = {kind: "close", label: I18n.t("action.close")} if simple
	end
end

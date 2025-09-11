# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
# frozen_string_literal: true

# SubmitComponent - ViewComponent to standardise form submissions/cancellations
class SubmitComponent < ApplicationComponent
	def initialize(close: :close, submit: nil, retlnk: nil, frame: nil)
		case close
		when :close
			label  = (submit == :save ? I18n.t("action.cancel"): I18n.t("action.close"))
		when :cancel
			cframe = frame
		end
		@close = ButtonComponent.new(kind: close, label:, url: retlnk, frame: cframe) if close
		if submit.class == Hash
			b_submit = submit
		elsif submit == :save # save button
			b_submit = { kind: :save }
		elsif submit # edit button with link in "submit"
			b_submit = { kind: :edit, url: submit, frame: }
		end
		@submit = ButtonComponent.new(**b_submit) if b_submit
	end

	def call	# render HTML
		content_tag(:div, class: "inline-flex align-middle flow-root mt-2 mb-1") do
			render_button(@close, "float-left mr-4 ml-1") if @close.present?
			render_button(@submit, "float-right ml-4 mr-1") if @submit.present?
		end
	end

	private
		def render_button(button, div_class)
			concat(content_tag(:div, class: div_class) do
				render(button)
			end)
		end
end

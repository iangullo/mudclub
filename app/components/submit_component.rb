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
	def initialize(close: :close, submit: nil, actions: [], retlnk: nil, frame: nil)
		@close   = build_close(close, submit, retlnk, frame)
		@submit  = build_submit(submit, frame)
		@actions = Array(actions).map { |cfg| ButtonComponent.new(**cfg) }
	end

	def call
		content_tag(:div, class: "inline-flex align-middle flow-root mt-2 mb-1") do
			render_button(@close, "float-left mr-4 ml-1") if @close.present?

			if @submit.present? || @actions.any?
				concat(content_tag(:div, class: "float-right ml-4 mr-1 inline-flex align-middle") do
					@actions.each do |b|
						concat(content_tag(:div, class: "ml-2") { render(b) })
					end
					concat(content_tag(:div, class: "ml-2") { render(@submit) }) if @submit.present?
				end)
			end
		end
	end

	private
		def build_close(kind, submit, retlnk, frame)
			return nil unless kind

			label =
				case kind
				when :close  then submit == :save ? I18n.t("action.cancel") : I18n.t("action.close")
				when :cancel then nil
				end

			ButtonComponent.new(kind:, label:, url: retlnk, frame: kind == :cancel ? frame : nil)
		end

		def build_submit(submit, frame)
			return nil if submit.nil?

			cfg =
				case submit
				when Hash  then submit
				when :save then { kind: :save }
				else            { kind: :edit, url: submit, frame: }
				end

			ButtonComponent.new(**cfg)
		end

		def render_button(button, div_class)
			concat(content_tag(:div, class: div_class) do
				render(button)
			end)
		end
end

# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
	attr_reader :close, :submit, :actions

	def initialize(close: :close, submit: nil, actions: [], retlnk: nil, frame: nil)
		@input   = { close:, submit:, actions:, retlnk:, frame: }
		@close   = build_close(close, submit, retlnk, frame)
		@submit  = build_submit(submit, frame)
		@actions = Array(actions).map { |cfg| ButtonComponent.new(**cfg) }
	end

	def call
		justify = "justify-#{@close.present? ? 'between' : 'end'}"
		content_tag(:div, class: "flex w-full items-center #{justify} gap-4 mt-2 mb-1") do
			if @close.present?
				concat(content_tag(:div) { render(@close) })
			end

			if @submit.present? || @actions.any?
				concat(content_tag(:div, class: "flex items-center gap-2") do
					@actions.each do |btn|
						concat(content_tag(:div) { render(btn) })
					end
					concat(content_tag(:div) { render(@submit) }) if @submit.present?
				end)
			end
		end
	end

	private
		def build_close(kind, submit, retlnk, frame)
			return nil unless kind

			label =
				case kind
				when :close  then submit == :save ? UI::Action.act(:cancel) : UI::Action.act(:close)
				when :cancel then nil
				end

			ButtonComponent.new(kind:, label:, url: retlnk, frame: kind == :cancel ? frame : nil)
		end

		def build_submit(submit, frame)
			return nil if submit.nil?

			cfg =
				case submit
				when Hash  then { frame:, **submit }
				when :save then { kind: :save }
				else            { kind: :edit, url: submit, frame: }
				end

			ButtonComponent.new(**cfg)
		end
end

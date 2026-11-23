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
# app/models/calendar/event_presenter/base.rb
class EventPresenter
	class Base
		attr_reader :event

		def initialize(event)           = @event = event
		def has_time?                   = true
		def slug                        = @event.kind
		def self.slugs                  = raise NotImplementedError
		def self.available_for?(_scope) = true

		# ------------------------------------------------------
		# UX presentation hooks
		# ------------------------------------------------------
		# Contract for subclasses:
		#   * Override only the hooks you need; inheriting the no-op
		#     default is the correct answer when a kind has no body.
		#   * Signatures in Base show the *guaranteed* arguments. A
		#     subclass may add keyword arguments (with defaults) to
		#     its override; it must not remove or rename these.
		#   * `view` is always a view context — `helpers` from a
		#     controller, `self` from a helper. Never a controller.
		#   * `header_fragments` is a pass-through of presentation
		#     state: base declares only `res:`, subclasses pick the
		#     rest out of `**`.
		# ------------------------------------------------------

		def header_fragments(view, res:, **)                  = res
		def show_fields(view, policy:, team: nil)             = []
		def show_targets(view, policy:, team: nil)            = nil
		def show_table(view, policy:, team: nil)              = nil
		def form_fields(view, policy:, team: nil, new: false) = []
		def form_table(view, policy:, team: nil, new: false)  = nil

		# Layout hints — pure data, no view
		def title_rows = nil	# holiday → 3
		def show_cols  = nil	# training → 3
		def form_cols  = nil	# match → 2

		# Unified notices management
		def created_notice = notice(:created) + notice_suffix
		def deleted_notice = notice(:deleted) + notice_suffix
		def updated_notice(initial, changed:)
			return I18n.t("status.no_data") unless changed
			return initial if initial == I18n.t("stat.updated")
			initial + notice_suffix
		end

		private

		def notice(verb)
			I18n.t("calendar.event.messages.#{verb}", kind: event.kind_label)
		end

		def notice_suffix = ": #{event.to_s(style: "notice")}"

		# --- shared accessors derivable from event ---
		def team     = @event.team
		def club     = team&.club || @event.club
		def sport    = team&.sport&.specific
		def category = team&.category
		def division = team&.division
		def season   = team&.season

		public

		# ---- still-to-be-extracted API ----
		def defaults(date: nil)     = raise NotImplementedError
		def symbol                  = raise NotImplementedError
		def to_s(style: nil)        = raise NotImplementedError
		def to_hash(mode: 1)        = raise NotImplementedError
		def unlink_cleanup          = nil

		# Renders kind-specific PDF content into the given pdf context.
		# `pdf_context` is the object that owns the PdfGenerator primitives
		# (pdf_label_text, pdf_subtitle, ...) — typically the controller.
		def pdf(view, _pdf_context) = nil
	end
end

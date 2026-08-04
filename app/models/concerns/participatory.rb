# MudClub - Modular Rails application for managing sports clubs.
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
# Participatory
#
# Group common definitions & methods for Membership/Assignment
#
module Participatory
	extend ActiveSupport::Concern

	included do
		enum :status, {
			pending: 0,
			active: 1,
			suspended: 2,
			terminated: 3,
			archived: 4
		}, prefix: true
	end

	def active?
		status.to_sym == :active
	end

	def current?
		starts_on <= Date.current &&
			(ends_on.nil? || ends_on >= Date.current) &&
			active?
	end

	def open?
		ends_on.nil?
	end

	def started?
		starts_on.present?
	end

	def terminated?
		status.to_sym == :terminated
	end

	def duration
		return nil unless starts_on

		(ends_on || Date.current) - starts_on
	end

	def date_range
		"#{starts_on} – #{ends_on || I18n.t('shared.statuses.active')}"
	end

	def status_label(variant = nil)
		I18n.t("shared.statuses.#{status}#{variant}")
	end
end

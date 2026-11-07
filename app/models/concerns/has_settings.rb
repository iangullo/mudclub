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
# app/models/concerns/has_settings.rb
#
# Shared storage contract for models that persist configuration in a JSON
# `settings` column. Provides symbol-keyed reads, string-keyed storage,
# and a merge-and-persist helper.
#
# Does NOT provide module logic — that lives in HasModules, which depends
# on this concern being included first.

module HasSettings
	extend ActiveSupport::Concern

	# Symbol-keyed reader. DB storage stays string-keyed (JSON), reads are
	# normalized so callers never care which shape the column held.
	def settings
		super&.deep_symbolize_keys || {}
	end

	def settings=(value)
		super(value&.to_h)
	end

	# Merge `attrs` into current settings and persist. Returns self so
	# callers can chain.
	def update_settings!(attrs)
		update!(settings: settings.merge(attrs.deep_symbolize_keys))
		self
	end
end

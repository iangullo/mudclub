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
# Behavior layer for Event#kind — mirrors Sport#specific.
#
# Convention: canonical catalog key :foo → EventKind::Foo.
# Aliases are resolved upstream by Kinded#kind, so `event.kind` is always
# canonical and dispatch is a plain const_get.
#
# Kinds without a specialized subclass fall back to Base, whose defaults
# reproduce the current code's "no dedicated branch" behavior. New
# catalog kinds get a working (if generic) implementation for free, and
# can be promoted to a subclass without touching Event or the helpers.
# app/models/calendar/event_kind.rb
class EventKind
	def self.specific(event:)
		kind = event.kind
		raise ArgumentError, "Event kind cannot be blank" if kind.blank?

		name = kind.to_s.camelize
		const_defined?(name, false) ? const_get(name).new(event) : Base.new(event)
	end

	def self.subclass_for(kind)
		name = kind.to_s.camelize
		const_defined?(name, false) ? const_get(name) : nil
	end

	def self.report_coverage!
		missing = Catalog::EventKinds.canonical.map(&:key).reject.reject do |key|
			const_defined?(key.to_s.camelize, false)
		end
		return if missing.empty?

		Rails.logger.info(
			"[EventKind] no specialized subclass for #{missing.inspect} — falling back to Base"
		)
	end
end

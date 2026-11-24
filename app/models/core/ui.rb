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

# app/models/core/ui.rb
# frozen_string_literal: true

module UI
	CONCEPTS = {
		Action:    :actions,
		Boolean:   :values,
		Color:     :values,
		Field:     :fields,
		Locale:    :values,
		Message:   :messages,
		Question:  :questions,
		Selection: :values,
		Setting:   :fields,
		Stat:      :fields,
		Status:    :values
	}.freeze

	class Base
		include Localizable
	end

	def self.const_missing(name)
		return super unless CONCEPTS.key?(name)

		default_scope = CONCEPTS[name]
		concept_key   = name.to_s.underscore

		klass = Class.new(Base) do
			localized_as :shared, concept_key
			key_scope default_scope
		end

		const_set(name, klass)
	end
end

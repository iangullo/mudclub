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
class ApplicationRecord < ActiveRecord::Base
	include Localizable
	include PgSearch::Model

	primary_abstract_class

	# Does this record have pending unsaved changes worth acting on?
	# Override in subclasses and call `super` to add domain-specific sources.
	def modified?
		changed? || attachments_changed? || rich_texts_changed?
	end

	# parse phone number using defined locale as p_country
	def parse_phone(p_number, p_ctry = nil)
		ctry = p_ctry || Phonelib.default_country
		Phonelib.parse(p_number.to_s.delete(" "), ctry).international.to_s
	end

	# read new field value, keep old value if empty & possible
	def read_field(dat_value, old_value, def_value)
		if dat_value    # we read & assign
			case dat_value.class
			when "String"
				dat_value
			when /Roo::/	# Roo excel CELL
				dat_value.value.to_s
			else	# anything else: convert to string
				dat_value.to_s
			end
		else    # assign default if no old value exists
			def_value unless old_value
		end
	end

	# return a 2 digit string for a number
	def two_dig(num)
		num.to_s.rjust(2, "0")
	end

	# starting / ending hours as string
	def timeslot_string(t_begin:, t_end: nil)
		cad = two_dig(t_begin.hour) + ":" + two_dig(t_begin.min)
		cad = cad + "-" + two_dig(t_end.hour) + ":" + two_dig(t_end.min) if t_end
		cad
	end

	# parse a value to determine if its true
	def to_boolean(value)
		val = value.presence
		(val.to_s == "true" || val.to_i == 1)
	end

	# def update object attachment
	def update_attachment(field, new_file = nil)
		if self.respond_to?(field)
			attachment = self.send(field)
			if new_file
				new_blob = new_file.read
				unless new_blob == attachment&.blob # Compare blob content
					attachment.purge if attachment.attached?
					attachment.attach(new_file)
				end
			end
		end
	end

	# Filter by a related record or its id.
	#
	#   Model.filter_by_id(:season_id, season)     # → where(season_id: season.id)
	#   Model.filter_by_id(:season_id, 5)          # → where(season_id: 5)
	#   Model.filter_by_id(:season_id, "5")        # → where(season_id: 5)
	#   Model.filter_by_id(:document_id, uuid_str) # → where(document_id: "…")
	#   Model.filter_by_id(:season_id, nil)        # → all
	#   Model.filter_by_id(:season_id, 0)          # → all
	#   Model.filter_by_id(:season_id, "")         # → all
	#
	# If an object of the wrong class is passed (and the expected class
	# can be derived from the column), returns `all` rather than
	# filtering by a coincidentally-matching id.
	def self.filter_by_id(column, value, klass: nil)
		return all if value.nil?

		# ---- object form ----
		if value.is_a?(ActiveRecord::Base)
			expected = klass || column.to_s.delete_suffix("_id").classify.safe_constantize
			raise ArgumentError, "expected #{expected}, got #{value.class}" if expected && !value.is_a?(expected)
			return all unless value.persisted?
			return where(column => value.id)
		end

		# ---- scalar form ----
		return all if value.blank?

		case value
		when Integer
			value.positive? ? where(column => value) : all
		when String
			value == "0" ? all : where(column => value)
		else
			all
		end
	end

	# definition / access to localization scopes
	def self.localized_as(scope)
		@i18n_scope = scope
	end

	def self.i18n_scope
		@i18n_scope
	end

	private

		def self.attachments_changed_on?(record)
			return false unless record.class.respond_to?(:attachment_reflections)

			record.class.attachment_reflections.each_key.any? do |name|
				!!record.public_send(name).changed?
			end
		end

		# True if any has_one_attached / has_many_attached on this class has a
		# pending in-memory change. Uses only public API:
		#   - attachment_reflections  (class_attribute, public)
		#   - attachment              (public reader on Attached::One / ::Many)
		#   - changed?                (public on the attachment AR record)
		def attachments_changed?
			self.class.attachments_changed_on?(self)
		end

		def rich_texts_changed?
			self.class.reflect_on_all_associations(:has_one)
					.select { |r| r.class_name == "ActionText::RichText" }
					.any? do |reflection|
						record = public_send(reflection.name)
						next false unless record

						record.new_record? ||
						record.changed? ||
						self.class.attachments_changed_on?(record)
					end
		end
end

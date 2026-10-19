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
# app/models/concerns/person_data.rb
module PersonData
	extend ActiveSupport::Concern

	SCALAR_ATTRIBUTES = %i[name surname birthday female dni email phone nick address].freeze
	ATTACHMENT_NAMES  = %i[avatar id_front id_back].freeze

	included do
		has_one_attached :avatar
		has_one_attached :id_front
		has_one_attached :id_back
	end

	# calculate age
	def age
		if self.birthday
			now  = Time.now.utc.to_date
			bday = self.birthday
			now.year - bday.year - ((now.month > bday.month || (now.month == bday.month && now.day >= bday.day)) ? 0 : 1)
		else
			0
		end
	end

	def minor?
		self.age < 18
	end

	# returns a hash of icon & label to mark whether a
	# Person has attached id pictures (front && back)
	def idpic_content
		label = self.dni
		symbol = { concept: "id_front", options: { title: Person.fld(:national_id) } }
		if self.idpics_attached?
			found  = true
		else
			found  = self.id_front.attached? || self.id_back.attached?
			symbol[:options][:title]  += " (#{I18n.t("person.pics_missing")})"
			symbol[:options][:variant] = "none"
		end
		{ found:, symbol:, label: }
	end

	# checks whether a Person has attached id pictures (front && back)
	def idpics_attached?
		self.id_front.attached? && self.id_back.attached?
	end

	# Scalars only by default. Pass include_attachments: true to fold in
	# the ActiveStorage blobs, keyed by attachment name, so the result can be
	# fed to Person#rebuild and reattach the same files on the target record.
	def person_attributes(include_attachments: false)
		attrs = slice(*SCALAR_ATTRIBUTES).symbolize_keys
		if include_attachments
			ATTACHMENT_NAMES.each do |name|
				att = public_send(name)
				attrs[name] = att.blob if att.attached?
			end
		end
		attrs
	end

	# personal image
	def picture
		self.avatar.attached? ? self.avatar : :person	# "person.svg"
	end

	# rebuild Person data from raw input (as hash) given by a form submittal
	def rebuild(data)
		self.dni       = data[:dni].presence			|| self.dni
		self.email     = data[:email].presence		|| self.email
		self.name      = data[:name].presence 		|| self.name
		self.surname   = data[:surname].presence 	|| self.surname
		self.address   = data[:address].presence 	|| self.address
		self.birthday  = data[:birthday].presence || self.birthday
		self.nick      = data[:nick].presence 		|| self.nick
		self.female    = to_boolean(data[:female])          if data[:female].present?
		self.phone     = parse_phone(data[:phone]) 					if data[:phone].presence
		self.update_attachment("avatar", data[:avatar])			if data[:avatar].present?
		self.update_attachment("id_front", data[:id_front]) if data[:id_front].present?
		self.update_attachment("id_back", data[:id_back]) 	if data[:id_back].present?

		rebuild_relationships(data[:relationships_attributes]) if data[:relationships_attributes]

		true
	end

	# short name for form viewing
	def s_name
		res = "#{self.to_s(false)} #{self.surname&.split&.first}"
		res.present? ? res : Person.label
	end

	def to_s(long = true)
		aux = self.nick.presence || self.name.to_s
		aux += " #{self.surname}" if long
		aux
	end

	# GDPR/LOPD compliance method - erase sensistive personal data
	def anonymize_data!
		return if anonymized_at.present?

		# Purge core sensitive document files attached locally
		ATTACHMENT_NAMES.each do |name|
			public_send(name).attachment&.destroy   # kills the join row, keeps the blob
		end

		# Reset structural references and unique string entities
		update!(
			dni: nil,
			birthday: nil,
			name: "Anonymized-#{SecureRandom.hex(3)}",
			nick: nil,
			surname: "Person-#{SecureRandom.hex(3)}",
			female: nil,
			email: nil,
			phone: nil,
			address: nil,
			anonymized_at: Time.current
		)
	end
end

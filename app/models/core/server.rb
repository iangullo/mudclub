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

# app/models/server.rb
class Server < ApplicationRecord
	localized_as "core.server"
	self.table_name = "server_settings"

	DATE_FORMATS = %i[default short long numeric].freeze

	#-------------------------------------
	# Validations
	#-------------------------------------
	validate :default_locale_is_valid
	validate :available_locales_are_known
	validate :time_zone_is_known
	validate :date_format_is_known
	validate :enabled_modules_are_known
	validate :enabled_modules_dependencies_satisfied

	#-------------------------------------
	# Included Modules
	#-------------------------------------
	include HasSettings
	include HasModules

	#-------------------------------------
	# Server configurable options
	#-------------------------------------

	# Free-form or multi-type settings, persisted as-is
	REGULAR_OPTS = %i[
		server_name server_logo tagline
		support_email contact_phone contact_address
		email_from email_reply_to email_signature
		default_locale time_zone date_format
		registrations_terms_url registrations_privacy_url
	].freeze

	REGULAR_OPTS.each do |opt|
		define_method(opt) { settings[opt].presence }
	end

	# Plain boolean settings (independent from module state)
	BOOLEAN_OPTS = %i[
		registrations_require_terms
		public_clubs_enabled public_directory_enabled
	].freeze

	BOOLEAN_OPTS.each do |opt|
		define_method(opt) { to_boolean(settings[opt].presence) }
		define_method("#{opt}?") { public_send(opt) }
	end

	#-------------------------------------
	# Class-level API
	#-------------------------------------
	class << self
		attr_reader :last_errors

		#-------------------------------------
		# Instance delegations
		#-------------------------------------
		delegate :server_name, :server_logo, :tagline,
						:support_email, :contact_phone, :contact_address,
						:email_from, :email_reply_to, :email_signature,
						:default_locale, :available_locales, :time_zone, :date_format,
						:enabled_modules, :disabled_modules,
						:registrations_enabled?, :registrations_require_terms, :registrations_require_terms?,
						:registrations_terms_url, :registrations_privacy_url,
						:public_clubs_enabled, :public_clubs_enabled?,
						:public_directory_enabled, :public_directory_enabled?,
						:settings, :module_enabled?, :enable_module!, :disable_module!,
						to: :current

		def instance
			@instance ||= find_by(id: 1) || create_default!
		end

		def create_default!
			create!(
				id: 1,
				settings: {
					enabled_modules:   [],   # nothing enabled by default
					available_locales: I18n.available_locales.map(&:to_s),
					default_locale:    I18n.default_locale.to_s,
					time_zone:         "UTC",
					date_format:       "default"
				}
			)
		rescue ActiveRecord::RecordNotUnique
			find(1)
		end

		def current
			Current.server_settings ||= instance
		end

		def reload!
			@instance = nil
			Current.server_settings = nil
		end

		# ─── Class-level option lists (for forms) ────────────────
		def boolean_option_list
			opts = []

			optional_modules.each do |mod|
				opts << [ I18n.t("core.modules.values.#{mod}"), mod ]
			end

			BOOLEAN_OPTS.each do |opt|
				opts << [ fld(opt), opt ]
			end

			opts
		end

		def locale_list
			I18n.available_locales.map do |locale|
				[ I18n.t("locale.#{locale}", locale:), locale ]
			end
		end

		def date_formats
			DATE_FORMATS.map { |fmt| [ t_path(:formats, fmt), fmt ] }
		end

		def time_zone_list
			zones = ActiveSupport::TimeZone.all.sort_by { |tz| [ tz.utc_offset, tz.name ] }
			utc   = zones.select { |tz| tz.name == "UTC" }
			rest  = zones.reject { |tz| tz.name == "UTC" }
			(utc + rest).map { |tz| [ "GMT#{tz.formatted_offset} · #{tz.name}", tz.name ] }
		end

		# ─── Mutators ────────────────────────────────────────────
		def rebuild!(attrs)
			record       = instance
			new_settings = record.settings.deep_dup

			REGULAR_OPTS.each do |opt|
				key = opt.to_s
				new_settings[opt] = attrs[key] if attrs.key?(key)
			end

			BOOLEAN_OPTS.each do |opt|
				key = opt.to_s
				new_settings[opt] = to_boolean(attrs[key]) if attrs.key?(key)
			end

			key = modules_key   # instance reader from class_attribute
			if attrs.key?(key.to_s) || attrs.key?(key)
				new_settings[key] = resolve_enabled_modules(attrs[key.to_s]) || resolve_enabled_modules(attrs[key])
			end

			if new_settings == record.settings
				@last_errors = []
				return false                     # ← "no change" path
			end

			record.update!(settings: new_settings)
			reload!
			@last_errors = []
			true
		rescue ActiveRecord::RecordInvalid => e
			@last_errors = e.record.errors.full_messages
			reload!
			false
		end
	end

	#-------------------------------------
	# Object-level API
	#-------------------------------------

	# ─── Identity ────────────────────────────────────────────
	def server_name
		settings[:server_name].presence || "MudClub"
	end

	def server_logo
		settings[:server_logo].presence || "mudclub.svg"
	end

	def tagline
		settings[:tagline].presence || self.fld(:tagline)
	end

	def support_email
		settings[:support_email]
	end

	def contact_phone
		settings[:contact_phone]
	end

	def contact_address
		settings[:contact_address]
	end

	# ─── Email fallbacks ─────────────────────────────────────
	def email_signature
		settings[:email_signature].presence ||
			[ server_name, support_email ].compact.join(" — ")
	end

	def email_from
		settings[:email_from].presence || support_email
	end

	def email_reply_to
		settings[:email_reply_to].presence || support_email
	end

	# ─── Localization ────────────────────────────────────────
	def default_locale
		(settings[:default_locale].presence || I18n.default_locale).to_sym
	rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
		nil
	end

	def available_locales
		Array(settings[:available_locales]).map(&:to_sym).presence ||
			I18n.available_locales
	end

	def time_zone
		(settings[:time_zone].presence || "UTC").to_s
	end

	def date_format
		(settings[:date_format].presence || :default).to_sym
	end

	# ─── Registration predicates ─────────────────────────────
	def registrations_enabled?
		module_enabled?(:admissions)
	end

	def registrations_require_terms?
		settings.fetch(:registrations_require_terms, true)
	end

	def registrations_terms_url
		settings[:registrations_terms_url]
	end

	def registrations_privacy_url
		settings[:registrations_privacy_url]
	end

	# ─── Public visibility ───────────────────────────────────
	def public_clubs_enabled
		settings.fetch(:public_clubs_enabled, false)
	end
	alias public_clubs_enabled? public_clubs_enabled

	def public_directory_enabled
		public_clubs_enabled? && settings.fetch(:public_directory_enabled, false)
	end
	alias public_directory_enabled? public_directory_enabled

	def registrations_require_terms
		settings.fetch(:registrations_require_terms, true)
	end
	alias registrations_require_terms? registrations_require_terms

	# ─── URL param ───────────────────────────────────────────
	def to_param = nil

	private

	# ─── Validators ──────────────────────────────────────────
	def default_locale_is_valid
		return if settings[:default_locale].blank?
		return if I18n.available_locales.include?(settings[:default_locale].to_sym)
		errors.add(:base, "default locale '#{settings[:default_locale]}' is not available")
	end

	def available_locales_are_known
		return if settings[:available_locales].blank?
		unknown = Array(settings[:available_locales]).map(&:to_sym) - I18n.available_locales
		return if unknown.empty?
		errors.add(:base, "unknown locales: #{unknown.join(', ')}")
	end

	def time_zone_is_known
		return if settings[:time_zone].blank?
		return if ActiveSupport::TimeZone[settings[:time_zone]]
		errors.add(:base, "unknown time zone '#{settings[:time_zone]}'")
	end

	def date_format_is_known
		return if DATE_FORMATS.include?(date_format)
		errors.add(:base, "unknown date format '#{date_format}'")
	end
end

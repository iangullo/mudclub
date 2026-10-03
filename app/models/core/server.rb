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
	BOOLEAN_OPTS = %i[public_clubs_enabled public_directory_enabled].freeze
	REGULAR_OPTS = %i[server_name support_email default_locale date_format].freeze

	#-------------------------------------
	# Validations
	#-------------------------------------
	validate :default_locale_is_valid
	validate :available_locales_are_known
	validate :time_zone_is_known
	validate :date_format_is_known

	#-------------------------------------
	# Delegations to instance
	#-------------------------------------
	class << self
		delegate :server_name, :server_logo, :tagline,
						:support_email, :contact_phone, :contact_address,
						:default_locale, :available_locales, :time_zone, :date_format,
						:enabled_modules, :disabled_modules,
						:registrations_enabled?, :registrations_require_terms?,
						:registrations_terms_url, :registrations_privacy_url,
						:public_clubs_enabled?, :public_directory_enabled?,
						:email_from, :email_reply_to, :email_signature,
						to: :current

		# Mutators and predicates that take args also delegate.
		delegate :module_enabled?, :enable_module!, :disable_module!,
						:dependencies_of, :dependents_of, :date_formats,
						:locale_list, :boolean_option_list, :admissions,
						:public_clubs_enabled?, :public_directory_enabled?,
						to: :current
	end

	#-------------------------------------
	# General API methods
	#-------------------------------------
	def to_param = nil

	def self.boolean_option_list
		opts = []
		optional_modules.each do |mod|
			opts << [ I18n.t("core.modules.values.#{mod}"), mod ]
		end

		BOOLEAN_OPTS.each do |opt|
			opts << [ Server.fld(opt), opt ]
		end

		opts
	end

	# list of possible user locales for select box configuration
	def self.locale_list
		opts = []
		I18n.available_locales.each do |locale|
			opts << [ I18n.t("locale.#{locale}", locale:), locale ]
		end

		opts
	end

	def self.date_formats
		opts = []
		DATE_FORMATS.each do |d_format|
			opts << [ t_path(:formats, d_format), d_format ]
		end

		opts
	end

	def admissions
		module_enabled?(:admissions) ? true : false
	end

	def public_clubs_enabled
		public_clubs_enabled? ? true : false
	end

	def public_directory_enabled
		public_directory_enabled? ?  true : false
	end

	# ─── Singleton ──────────────────────────────────────────────
	def self.instance
		@instance ||= begin
			first_or_create!(id: 1)
		rescue ActiveRecord::RecordNotUnique
			find(1)
		end
	end

	def self.current
		Current.server_settings ||= instance
	end

	def self.reload!
		@instance = nil
		Current.server_settings = nil
	end

	def self.rebuild!(attrs)
		self.transaction do
			new_settings = instance.settings.dup
			REGULAR_OPTS.each do |opt|
				new_settings[opt.to_sym] = attrs[opt.to_s] if attrs[opt.to_s].present?
			end

			BOOLEAN_OPTS.each do |opt|
				new_settings[opt.to_sym] = to_boolean(attrs[opt.to_s]) if attrs[opt.to_s].present?
			end

			if instance.update_settings!(new_settings)
				optional_modules do |opt|
					opt.to_boolean ? instance.enable_module!(opt) : instance.disable_module!(opt)
				end
				return true
			end
			false
		end

		false
	end

	# ─── Settings hash ──────────────────────────────────────────
	def settings
		super&.deep_symbolize_keys || {}
	end

	def settings=(value)
		super(value&.to_h)
	end

	def update_settings!(attrs)
		update!(settings: settings.merge(attrs.deep_symbolize_keys))
		self.class.reload!
		self
	end

	# ─── Module catalog queries ─────────────────────────────────
	def self.core_modules     = Catalog::Modules.where(optional: false).map(&:key)
	def self.optional_modules = Catalog::Modules.where(optional: true).map(&:key)
	def self.all_modules      = Catalog::Modules.keys

	def disabled_modules
		Array(settings[:disabled_modules]).map(&:to_s)
	end

	def module_enabled?(name)
		entry = Catalog::Modules[name]
		return false unless entry
		return true unless entry[:optional]
		!disabled_modules.include?(name.to_s)
	end

	def enabled_modules
		self.class.all_modules.select { |m| module_enabled?(m) }
	end

	def dependencies_of(name)
		Array(Catalog::Modules[name]&.dig(:dependencies)).map(&:to_s)
	end

	def dependents_of(name)
		target = name.to_s
		seen   = Set.new
		queue  = [ target ]

		until queue.empty?
			current = queue.shift
			Catalog::Modules.keys.each do |k|
				key = k.to_s
				next if seen.include?(key)
				next unless dependencies_of(key).include?(current)
				seen << key
				queue << key
			end
		end
		seen.to_a
	end

	def enable_module!(name)
		name = name.to_s
		return false unless Catalog::Modules.include?(name)

		missing = dependencies_of(name).select do |d|
			dep = Catalog::Modules[d]
			dep && dep[:optional] && !module_enabled?(d)
		end

		update_settings!(disabled_modules: disabled_modules - [ name ] - missing)
		true
	end

	def disable_module!(name)
		name = name.to_s
		entry = Catalog::Modules[name]
		return false unless entry && entry[:optional]

		cascade = dependents_of(name)
		update_settings!(disabled_modules: (disabled_modules | [ name ] | cascade).uniq)
		true
	end

	# ─── Identity ───────────────────────────────────────────────
	def server_name
		settings[:server_name].presence || "MudClub"
	end

	def server_logo
		settings[:server_logo].presence || "mudclub.svg"
	end

	def tagline
		settings[:tagline] || self.fld(:tagline)
	end

	def support_email
		settings[:support_email]
	end

	def email_signature
		settings[:email_signature]
	end

	# ─── Localization ───────────────────────────────────────────
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

	# ─── Registration policy (server-wide) ──────────────────────
	def registrations_enabled?
		settings.fetch(:registrations_enabled, false)
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

	def public_clubs_enabled?
		settings.fetch(:public_clubs_enabled, false)
	end

	def public_directory_enabled?
		settings.fetch(:public_directory_enabled, false) && public_clubs_enabled?
	end
	alias public_directory_enabled public_directory_enabled?

	# ─── Email ──────────────────────────────────────────────────
	def email_from
		settings[:email_from].presence || support_email
	end

	def email_reply_to
		settings[:email_reply_to].presence || support_email
	end

	private

	def available_locales_are_known
		return if settings[:available_locales].blank?
		unknown = Array(settings[:available_locales]).map(&:to_sym) - I18n.available_locales
		return if unknown.empty?
		errors.add(:base, "unknown locales: #{unknown.join(', ')}")
	end

	def default_locale_is_valid
		return if settings[:default_locale].blank?
		return if I18n.available_locales.include?(settings[:default_locale].to_sym)
		errors.add(:base, "default locale '#{settings[:default_locale]}' is not available")
	end

	def date_format_is_known
		return if DATE_FORMATS.include?(date_format)
		errors.add(:base, "unknown date format '#{date_format}'")
	end

	def time_zone_is_known
		return if settings[:time_zone].blank?
		return if ActiveSupport::TimeZone[settings[:time_zone]]
		errors.add(:base, "unknown time zone '#{settings[:time_zone]}'")
	end
end

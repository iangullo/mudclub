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

# app/services/infrastructure.rb
class Infrastructure
	IMAGE_PROCESSING_AVAILABLE = begin
		require "vips"
		true
	rescue LoadError
		begin
			require "mini_magick"
			system("which convert > /dev/null 2>&1") || false
		rescue LoadError
			false
		end
	end

	CAPABILITIES = {
		postgresql:          :postgresql?,
		solid_stack:         :solid_stack?,
		background_jobs:     :background_jobs?,
		persistent_cache:    :persistent_cache?,
		active_storage:      :active_storage?,
		persistent_storage:  :persistent_storage?,
		image_processing:    :image_processing?,
		full_text_search:    :full_text_search?,
		action_cable:        :action_cable?,
		smtp_configured:     :smtp_configured?,
		mail_deliverable:    :mail_deliverable?,
		database_writable:   :database_writable?
	}.freeze

	def self.available?(capability)
		method = CAPABILITIES[capability.to_sym]
		return true if method.nil?
		public_send(method)
	end

	def self.diagnostics
		CAPABILITIES.keys.index_with { |cap| available?(cap) }
	end

	private

	def self.cache
		@cache ||= {}
	end

	def self.action_cable?
		cable   = ActionCable.server.config.cable || {}
		adapter = cable[:adapter] || cable["adapter"]
		adapter.present? && adapter.to_sym != :test
	end

	def self.active_storage?
		svc = Rails.application.config.active_storage.service&.to_sym
		svc.present? && svc != :test
	end

	def self.background_jobs?
		adapter = Rails.application.config.active_job.queue_adapter
		adapter.present? && ![ :inline, :async ].include?(adapter.to_sym)
	end

	def self.database_writable?
		ActiveRecord::Base.connection_db_config.replica? != true
	end

	def self.full_text_search?
		postgresql?
	end

	def self.image_processing?
		IMAGE_PROCESSING_AVAILABLE
	end

	def self.mail_deliverable?
		method = Rails.application.config.action_mailer.delivery_method
		method.present? && ![ :test, :logger, :file, :letter_opener ].include?(method)
	end

	def self.persistent_cache?
		store = Array(Rails.application.config.cache_store).first&.to_sym
		store.present? && ![ :memory_store, :null_store ].include?(store)
	end

	def self.persistent_storage?
		active_storage? && ![ :local ].include?(Rails.application.config.active_storage.service.to_sym)
	end

	def self.postgresql?
		ActiveRecord::Base.connection_db_config.adapter.to_s == "postgresql"
	end

	def self.solid_stack?
		queue = Rails.application.config.active_job.queue_adapter.to_s
		cache = Array(Rails.application.config.cache_store).first.to_s
		queue == "solid_queue" && cache.include?("solid_cache")
	end

	def self.smtp_configured?
		return false unless Rails.application.config.action_mailer.delivery_method == :smtp
		s = Rails.application.config.action_mailer.smtp_settings || {}
		s[:address].present? && s[:port].present?
	end
end

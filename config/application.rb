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
require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mudclub
	class Application < Rails::Application
		# Initialize configuration defaults for originally generated Rails version.
		config.load_defaults 8.0

		# Please, add to the `ignore` list any other `lib` subdirectories that do
		# not contain `.rb` files, or that should not be reloaded or eager loaded.
		# Common ones are `templates`, `generators`, or `middleware`, for example.
		config.autoload_lib(ignore: %w[assets tasks])
		config.eager_load_paths << Rails.root.join("lib", "symbols")

		# Configuration for the application, engines, and railties goes here.

		#
		# Domain folders
		#
		DOMAINS = %w[
			calendar
			core
			organization
			participation
			people
			training
		].freeze

		DOMAINS.each do |domain|
			%w[models controllers].each do |root|
				path = Rails.root.join("app", root, domain)

				config.autoload_paths << path
				config.eager_load_paths << path
			end
		end

		#
		# Sports extensions
		#
		Dir[Rails.root.join("app/sports/*")].each do |path|
			config.autoload_paths << path
			config.eager_load_paths << path
		end

		# These settings can be overridden in specific environments using the files
		# in config/environments, which are processed later.
		#
		# config.time_zone = "Central Time (US & Canada)"
		# config.eager_load_paths << Rails.root.join("extras")
		[ Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone ]
	end
end

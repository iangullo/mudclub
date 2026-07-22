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

		# Add all subdirectories of app/models to the load path
		config.autoload_paths += Dir[Rails.root.join("app/models/*")]
		config.eager_load_paths += Dir[Rails.root.join("app/models/*")]

		# Add controllers subdirectories too
		config.autoload_paths += Dir[Rails.root.join("app/controllers/*")]
		config.eager_load_paths += Dir[Rails.root.join("app/controllers/*")]

		# Allow views to be loaded from subdirectories (future-proof)
		# This won't break anything now, and will work when you move views later
		config.paths["app/views"] << "app/views/core"
		config.paths["app/views"] << "app/views/people"
		config.paths["app/views"] << "app/views/organization"
		config.paths["app/views"] << "app/views/activities"
		config.paths["app/views"] << "app/views/training"
		config.paths["app/views"] << "app/views/participation"

		# These settings can be overridden in specific environments using the files
		# in config/environments, which are processed later.
		#
		# config.time_zone = "Central Time (US & Canada)"
		# config.eager_load_paths << Rails.root.join("extras")
		[ Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone ]
	end
end

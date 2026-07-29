# lib/tasks/i18n.rake

namespace :i18n do
	desc "Verify that Localizable models and catalogs have locale entries"
	task verify: :environment do
		Rails.application.eager_load!

		missing = []

		#
		# ActiveRecord models
		#
		ApplicationRecord.descendants
										.select { |k| k.respond_to?(:i18n_scope) }
										.sort_by(&:name)
										.each do |klass|
			scope = klass.i18n_scope

			unless I18n.exists?("#{scope}.label.single")
				missing << "#{klass.name}: #{scope}.label.single"
			end

			unless I18n.exists?("#{scope}.label.plural")
				missing << "#{klass.name}: #{scope}.label.plural"
			end
		end

		#
		# Catalogs
		#
		Catalog::Base.descendants
								.sort_by(&:name)
								.each do |catalog|
			scope = catalog.i18n_scope

			catalog::CATALOG.each_key do |member|
				next if catalog::CATALOG[member][:deprecated]

				key = "#{scope}.values.#{member}.label"

				unless I18n.exists?(key)
					missing << "#{catalog.name}: #{key}"
				end
			end
		end

		puts

		if missing.empty?
			puts "✔ All models and catalog entries have locale definitions."
		else
			puts "Missing locale entries:"
			puts

			missing.each do |entry|
				puts "  ✗ #{entry}"
			end

			abort "\n#{missing.count} missing locale entries."
		end
	end
end

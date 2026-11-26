# test/i18n/locale_parity_test.rb
require "test_helper"

class LocaleParityTest < ActiveSupport::TestCase
	# Keys that legitimately exist in Spanish (grammatical gender/plural forms)
	# without requiring a 1-to-1 English counterpart.
	ES_ONLY_KEY_PATTERN = /(?:_female|_plural|_plural_female|_short_female|\.gender(?:\.|$)|(?:^|\.):?female(?:\.|$))/

	# Sport-specific terms that are optional across languages and rely on fallbacks
	OPTIONAL_SPORT_KEY_PATTERN = /\Asport\.[^.]+\./

	# Discover every locale directory in config/locales/* and app/sports/*/locales
	LOCALE_DIRS = (
		Dir.glob(Rails.root.join("config/locales/*")).select { |p| File.directory?(p) } +
		Dir.glob(Rails.root.join("app/sports/*/locales")).select { |p| File.directory?(p) }
	).sort.freeze

	LOCALE_DIRS.each do |dir|
		domain_name = dir.sub("#{Rails.root}/", "")
		is_sport_domain = domain_name.start_with?("app/sports/")

		test "#{domain_name} has complete EN <-> ES key parity" do
			en_file = File.join(dir, "en.yml")
			es_file = File.join(dir, "es.yml")

			assert File.exist?(en_file), "Missing #{en_file}"
			assert File.exist?(es_file), "Missing #{es_file}"

			en_tree = YAML.safe_load_file(en_file, aliases: true).fetch("en", {})
			es_tree = YAML.safe_load_file(es_file, aliases: true).fetch("es", {})

			en_keys = flatten_keys(en_tree)
			es_keys = flatten_keys(es_tree)

			raw_missing_in_es = en_keys - es_keys
			raw_missing_in_en = (es_keys - en_keys).reject { |k| k.match?(ES_ONLY_KEY_PATTERN) }

			if is_sport_domain
				warn_sport_fallbacks(domain_name, "es.yml (falls back to en)", raw_missing_in_es)
				warn_sport_fallbacks(domain_name, "en.yml (sport-specific ES term)", raw_missing_in_en)
			else
				optional_es, required_missing_in_es = raw_missing_in_es.partition { |k| k.match?(OPTIONAL_SPORT_KEY_PATTERN) }
				optional_en, required_missing_in_en = raw_missing_in_en.partition { |k| k.match?(OPTIONAL_SPORT_KEY_PATTERN) }

				warn_sport_fallbacks(domain_name, "es.yml (falls back to en)", optional_es)
				warn_sport_fallbacks(domain_name, "en.yml (sport-specific ES term)", optional_en)

				assert_empty required_missing_in_es,
					"[#{domain_name}] Keys present in en.yml but missing in es.yml:\n  - #{required_missing_in_es.join("\n  - ")}"
				assert_empty required_missing_in_en,
					"[#{domain_name}] Keys present in es.yml but missing in en.yml:\n  - #{required_missing_in_en.join("\n  - ")}"
			end
		end
	end

	private

		def warn_sport_fallbacks(domain_name, target_label, keys)
			return if keys.empty?

			warn "\n[I18n Warning] [#{domain_name}] Optional sport keys missing in #{target_label}:\n  - #{keys.join("\n  - ")}"
		end

		def flatten_keys(node, prefix = nil)
			return [] unless node.is_a?(Hash)

			node.each_with_object([]) do |(key, value), acc|
				next if key.to_s == "helpers" || key.to_s == "views"

				path = [ prefix, key ].compact.join(".")
				if value.is_a?(Hash)
					acc.concat(flatten_keys(value, path))
				else
					acc << path
				end
			end
		end
end

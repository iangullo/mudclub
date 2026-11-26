# lib/tasks/i18n_sync.rake
namespace :i18n do
	desc "Scaffold missing EN <-> ES locale keys with TODO placeholders"
	task sync_parity: :environment do
		inflection_suffixes = %w[_female _plural _plural_female _short_female .gender]

		dirs = (
			Dir.glob(Rails.root.join("config/locales/*")).select { |p| File.directory?(p) } +
			Dir.glob(Rails.root.join("app/sports/*/locales")).select { |p| File.directory?(p) }
		).sort

		deep_merge_missing = lambda do |target, source, lang_tag|
			source.each do |k, v|
				if v.is_a?(Hash)
					target[k] = {} unless target[k].is_a?(Hash)
					deep_merge_missing.call(target[k], v, lang_tag)
				elsif !target.key?(k)
					target[k] = "[TODO #{lang_tag}] #{v}"
				end
			end
		end

		dirs.each do |dir|
			en_file = File.join(dir, "en.yml")
			es_file = File.join(dir, "es.yml")
			next unless File.exist?(en_file) && File.exist?(es_file)

			en_data = YAML.safe_load_file(en_file, aliases: true)
			es_data = YAML.safe_load_file(es_file, aliases: true)

			en_tree = en_data["en"] ||= {}
			es_tree = es_data["es"] ||= {}

			# Fill missing keys in es.yml from en.yml
			deep_merge_missing.call(es_tree, en_tree, "ES")

			File.write(es_file, es_data.to_yaml(line_width: -1))
			puts "Updated #{es_file.sub("#{Rails.root}/", "")}"
		end
	end
end

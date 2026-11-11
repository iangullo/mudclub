# test/catalogs/catalog_contract.rb
#
# Shared assertions every Catalog::* class must satisfy.
# Include it in a test class and define `catalog` returning the class:
#
#   class DocumentStatusesTest < ActiveSupport::TestCase
#     include CatalogContract
#     def catalog = Catalog::DocumentStatuses
#   end
#
module CatalogContract
	def test_catalog_declares_a_domain
		assert catalog.instance_variable_get(:@domain).present?,
			"#{catalog} does not declare a domain"
	end

	def test_catalog_entries_are_non_empty
		assert_kind_of Hash, catalog.entries
		refute_empty catalog.entries
	end

	def test_catalog_keys_match_raw_catalog
		raw_keys = catalog.const_get(:CATALOG).keys.map(&:to_sym)
		assert_equal raw_keys.sort, catalog.keys.sort
	end

	def test_catalog_enum_maps_keys_to_integer_ids
		assert_kind_of Hash, catalog.enum
		catalog.enum.each do |key, id|
			assert_kind_of Symbol,  key
			assert_kind_of Integer, id
		end
	end

	def test_catalog_ids_are_unique
		raw = catalog.const_get(:CATALOG)
		ids = raw.reject { |_k, m| m[:alias_of] }.map { |_k, m| m[:id] }
		assert_equal ids.uniq, ids, "#{catalog} has duplicate ids"
	end

	def test_catalog_id_and_key_are_bijective
		catalog.enum.each do |key, id|
			assert_equal id,  catalog.id(key),  "id(#{key.inspect}) mismatch"
			assert_equal key, catalog.key(id),  "key(#{id}) mismatch"
			assert_equal key, catalog.entry(id).key
		end
	end

	def test_catalog_normalize_handles_strings_symbols_and_nil
		sample = catalog.keys.first
		assert_equal sample, catalog.normalize(sample.to_s)
		assert_equal sample, catalog.normalize(sample.to_s.titleize)
		assert_nil catalog.normalize(nil)
	end

	def test_catalog_fetch_accepts_symbols_and_strings
		key = catalog.keys.first
		assert_equal catalog.fetch(key), catalog.fetch(key.to_s)
		assert_equal catalog[key],       catalog.fetch(key)
	end

	def test_catalog_include_predicate
		key = catalog.keys.first
		assert catalog.include?(key),              "include?(#{key.inspect}) failed"
		refute catalog.include?(:__missing_key__)
	end

	def test_catalog_where_and_find_by
		entry = catalog.first
		assert_includes catalog.where(id: entry.id).map(&:key), entry.key
		assert_equal entry, catalog.find_by(id: entry.id)
	end

	def test_catalog_resolves_aliases_to_canonical_entry
		aliases = catalog.entries.values.select(&:alias?)
		skip "#{catalog.name} declares no aliases" if aliases.empty?

		aliases.each do |entry|
			assert_equal catalog.fetch(entry.alias_of), catalog.resolve(entry.key),
				"alias #{entry.key} did not resolve to #{entry.alias_of}"
		end
	end

	def test_catalog_i18n_scope_is_domain_prefixed
		domain = catalog.instance_variable_get(:@domain)
		assert catalog.i18n_scope.start_with?("#{domain}."),
			"#{catalog}.i18n_scope = #{catalog.i18n_scope.inspect} does not start with #{domain}."
		assert catalog.i18n_scope.end_with?(catalog.name.demodulize.underscore)
	end

	def test_catalog_key_scope_defaults_to_values
		assert_equal :values, catalog.i18n_key_scope,
			"#{catalog} should resolve labels under the :values sub-scope " \
			"(add `def i18n_key_scope = i18n_members_scope` to Catalog::Base)"
	end

	def test_catalog_every_key_has_a_values_translation
		catalog.keys.each do |key|
			direct = I18n.t("#{catalog.i18n_scope}.values.#{key}", default: nil)
			assert direct.present?,
				"#{catalog}::#{key} is missing a .values.#{key} translation"
		end
	end

	def test_catalog_entries_are_sorted_by_id
		ids = catalog.values.map(&:id)
		assert_equal ids.sort, ids
	end
end

# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
# lib/symbols/symbol_registry.rb
# Serve SVG symbols to objects from the application
require "set"

class SymbolRegistry
	CONFIG = YAML.safe_load(
		File.read(Rails.root.join("config/symbol_map.yml")),
		aliases: true,
		symbolize_names: false
	).with_indifferent_access

	def initialize(namespace)
		@namespace = namespace.to_s
		@paths = CONFIG[@namespace] || {}
		raise "Namespace '#{@namespace}' not found in symbol_map.yml" if @paths.empty?
	end

	# Preload all symbols in this namespace and cache them
	def preload_namespace!
		@paths.each do |type, _|
			doc = load_svg(type.to_s)
			next unless doc

			doc.css("symbol[id]").each do |symbol|
				id = symbol["id"]
				unless self.class.symbol_cache[@namespace][id]
					resolve_use_tags(symbol, type: type, visited: Set.new)
					self.class.symbol_cache[@namespace][id] = symbol
				end
			end
		end
	end

	# Fetch a symbol by concept/variant/type from the cache or file
	def find_symbol(concept, variant = "default", type: :icon)
		id = SymbolRegistry.symbol_id(concept, variant)

		self.class.symbol_cache[@namespace][id] ||= begin
			doc = load_svg(type.to_s)
			symbol = doc&.at_css("symbol[id='#{id}']")
			resolve_use_tags(symbol, type: type, visited: Set.new) if symbol
			symbol
		end
	end

	# Check if a symbol exists
	def symbol_exists?(concept, variant = "default", type: :icon)
		!!find_symbol(concept, variant, type: type)
	end

	# Static caches: one for parsed SVGs, one for resolved symbols
	def self.doc_cache
		@doc_cache ||= Hash.new { |hash, ns| hash[ns] = {} }
	end

	def self.symbol_cache
		@symbol_cache ||= Hash.new { |hash, ns| hash[ns] = {} }
	end

	# Fetch a symbol directly using class-level API
	def self.fetch(namespace:, type: :object, concept:, variant: "default")
		new(namespace).find_symbol(concept, variant, type: type)
	end

	# Preload all namespaces defined in the config
	def self.preload_all!
		CONFIG.each_key do |namespace|
			new(namespace).preload_namespace!
		end
	end

	# Compose a symbol ID from concept and variant
	def self.symbol_id(concept, variant = "default")
		"#{concept}.#{variant}"
	end

	private

	# Load and cache SVG file contents (parsed as Nokogiri XML)
	def load_svg(type)
		path = svg_path(type)
		return unless path&.exist?
	
		self.class.doc_cache[@namespace][path.to_s] ||= begin
			content = File.read(path)
			Nokogiri::XML(content)
		rescue StandardError => e
			Rails.logger.warn "Failed to load SVG file #{path}: #{e.message}"
			nil
		end
	end

	# Resolve <use> references recursively by inlining referenced symbols
	def resolve_use_tags(symbol, type:, visited:)
		return unless symbol

		symbol.css("use[href]").each do |use_tag|
			ref_id = use_tag["href"]&.sub(/^#/, "")
			next unless ref_id
			next if visited.include?(ref_id)

			visited.add(ref_id)
			referenced = find_symbol_by_id(ref_id, type: type, visited: visited)

			if referenced
				resolve_use_tags(referenced, type: type, visited: visited)

				referenced.children.each do |child|
					use_tag.add_previous_sibling(child.dup)
				end
				use_tag.remove
			end
		end
	end

	# Helper for resolving a symbol by ID, with cache and recursion
	def find_symbol_by_id(id, type:, visited:)
		self.class.symbol_cache[@namespace][id] ||= begin
			doc = load_svg(type.to_s)
			symbol = doc&.at_css("symbol[id='#{id}']")
			resolve_use_tags(symbol, type: type, visited: visited) if symbol
			symbol
		end
	end


	# Compute the full path to the SVG file for a given type
	def svg_path(type)
		rel_path = @paths[type]
		return unless rel_path

		Rails.root.join("app/assets/symbols", rel_path)
	end
end

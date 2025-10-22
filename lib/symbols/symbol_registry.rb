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

	# constants for missing symbol
	MISSING_SYMBOL_ID = "missing.default"

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
	# Returns missing symbol if not found
	def find_symbol(concept, variant = "default", type: :icon)
		id = SymbolRegistry.symbol_id(concept, variant)

		# Try to find symbol in current namespace
		symbol = fetch_symbol(@namespace, id, type)

		# Fallback to missing symbol if not found
		symbol || fetch_missing_symbol
	end

	# Check if a symbol exists (doesn't use missing symbol fallback)
	def symbol_exists?(concept, variant = "default", type: :icon)
		id = SymbolRegistry.symbol_id(concept, variant)
		!!fetch_symbol(@namespace, id, type, check_only: true)
	end

	# Static caches: one for parsed SVGs, one for resolved symbols
	def self.doc_cache
		@doc_cache ||= Hash.new { |hash, ns| hash[ns] = {} }
	end

	def self.symbol_cache
		@symbol_cache ||= Hash.new { |hash, ns| hash[ns] = {} }
	end

	# Fetch a symbol directly using class-level API
	def self.fetch(namespace: "common", type: :icon, concept:, variant: "default")
		new(namespace).find_symbol(concept, variant, type:)
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

	# Fetch a symbol from a specific namespace with optional check-only mode
	def fetch_symbol(namespace, id, type, check_only: false)
		# Check cache first
		return self.class.symbol_cache[namespace][id] if self.class.symbol_cache[namespace][id]

		# Load from file if not in cache
		doc = load_svg_for_namespace(namespace, type.to_s)
		symbol = doc&.at_css("symbol[id='#{id}']")

		if symbol && !check_only
			resolve_use_tags(symbol, type: type, visited: Set.new)
			self.class.symbol_cache[namespace][id] = symbol
		end

		symbol
	end

	# Fetch missing symbol (from common namespace by default)
	def fetch_missing_symbol
		fetch_symbol("common", MISSING_SYMBOL_ID, :icon) || create_default_missing_symbol
	end

	# Create a default missing symbol as fallback
	def create_default_missing_symbol
		doc = Nokogiri::XML::Document.new
		symbol = Nokogiri::XML::Node.new("symbol", doc)
		symbol["id"] = MISSING_SYMBOL_ID
		symbol["viewBox"] = "0 0 24 24"

		# Create a simple "missing" indicator (question mark in a circle)
		circle = Nokogiri::XML::Node.new("circle", doc)
		circle["cx"] = "12"
		circle["cy"] = "12"
		circle["r"] = "10"
		circle["stroke"] = "currentColor"
		circle["stroke-width"] = "2"
		circle["fill"] = "none"

		text = Nokogiri::XML::Node.new("text", doc)
		text["x"] = "12"
		text["y"] = "16"
		text["text-anchor"] = "middle"
		text["fill"] = "currentColor"
		text["font-size"] = "12"
		text["font-weight"] = "bold"
		text.content = "?"

		symbol.add_child(circle)
		symbol.add_child(text)

		# Cache the created symbol in common namespace
		self.class.symbol_cache["common"][MISSING_SYMBOL_ID] = symbol
		symbol
	end

	# Load SVG for a specific namespace
	def load_svg_for_namespace(namespace, type)
		paths = namespace == @namespace ? @paths : CONFIG[namespace]
		return unless paths && paths[type]

		path = Rails.root.join("app/assets/symbols", paths[type])
		return unless path.exist?

		self.class.doc_cache[namespace][path.to_s] ||= begin
			content = File.read(path)
			Nokogiri::XML(content)
		rescue StandardError => e
			Rails.logger.warn "Failed to load SVG file #{path}: #{e.message}"
			nil
		end
	end

	# Alias for backward compatibility
	def load_svg(type)
		load_svg_for_namespace(@namespace, type)
	end

	# Resolve <use> references recursively by inlining referenced symbols
	def resolve_use_tags(symbol, type:, visited:)
		return unless symbol

		symbol.css("use[href]").each do |use_tag|
			ref_id = use_tag["href"]&.sub(/^#/, "")
			next unless ref_id
			next if visited.include?(ref_id)

			visited.add(ref_id)
			referenced = fetch_symbol(@namespace, ref_id, type)

			if referenced
				resolve_use_tags(referenced, type: type, visited: visited)

				# Wrap in <g> with transform from <use>, if any
				group = Nokogiri::XML::Node.new("g", symbol.document)
				transform_attr = use_tag["transform"]
				group["transform"] = transform_attr if transform_attr

				# Also copy fill/stroke/class if you want to be thorough:
				%w[fill stroke class style].each do |attr|
					group[attr] = use_tag[attr] if use_tag[attr]
				end

				referenced.children.each do |child|
					group.add_child(child.dup)
				end
				use_tag.replace(group)
			end
		end
	end

	# Compute the full path to the SVG file for a given type
	def svg_path(type)
		rel_path = @paths[type]
		return unless rel_path

		Rails.root.join("app/assets/symbols", rel_path)
	end

	# -- Utility methods for converting symbols to image data URLs --

	# Convert a Nokogiri <symbol> node into a standalone <svg> string and encode as data URL
	def self.image_data_url(symbol_node, width: 128, height: 128)
		return nil unless symbol_node.is_a?(Nokogiri::XML::Node)

		view_box = symbol_node["viewBox"] || "0 0 #{width} #{height}"

		svg_markup = <<~SVG
			<svg xmlns="http://www.w3.org/2000/svg"
					viewBox="#{view_box}"
					width="#{width}"
					height="#{height}"
					preserveAspectRatio="xMidYMid meet">
				#{symbol_node.children.to_xml}
			</svg>
		SVG

		encoded = Base64.strict_encode64(svg_markup.strip)
		"data:image/svg+xml;base64,#{encoded}"
	end

	# Fetch a symbol from the registry and return its encoded data URL
	def self.to_image_data(namespace: "common", type: :icon, concept:, variant: "default", width: 128, height: 128)
		symbol_node = fetch(namespace:, type:, concept:, variant:)
		image_data_url(symbol_node, width:, height:)
	end
end

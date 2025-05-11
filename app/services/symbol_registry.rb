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
# Serve SVG symbols to objects from the application
class SymbolRegistry
  CONFIG = YAML.load_file(Rails.root.join("config/symbol_map.yml")).with_indifferent_access

  def self.doc_cache
    @doc_cache ||= Hash.new { |hash, key| hash[key] = {} }
  end

  def self.symbol_cache
    @symbol_cache ||= Hash.new { |hash, key| hash[key] = {} }
  end

  def self.preload_all!
    CONFIG.each_key do |namespace|
      registry = new(namespace)
      registry.preload_namespace!
    end
  end

  def preload_namespace!
    @paths.each do |type, _|
      doc = load_svg(type.to_s)
      next unless doc

      doc.css("symbol[id]").each do |symbol|
        id = symbol["id"]
        self.class.symbol_cache[@namespace][id] ||= symbol
      end
    end
  end

  def initialize(namespace)
    @namespace = namespace.to_s
    @paths = CONFIG[@namespace] || {}
    raise "Namespace '#{@namespace}' not found in symbol_map.yml" if @paths.empty?
  end

  def find_symbol(concept, variant = "default", type: :objects)
    symbol_id = "#{concept}.#{variant}"
    self.class.symbol_cache[@namespace][symbol_id] ||= begin
      doc = load_svg(type.to_s)
      doc&.at_css("symbol[id='#{symbol_id}']")
    end
  end

  private

  def load_svg(type)
    path = svg_path(type)
    return unless path && File.exist?(path)

    self.class.doc_cache[@namespace][path.to_s] ||= Nokogiri::XML(File.read(path))
  end

  def svg_path(type)
    rel_path = @paths[type]
    return unless rel_path

    Rails.root.join("app/assets/symbols", rel_path)
  end
end

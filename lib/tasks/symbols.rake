# lib/tasks/symbols.rake
namespace :symbols do
  desc "Verify that all SVG symbols and their references are valid"
  task verify: :environment do
    puts "[SymbolRegistry] Verifying integrity of SVG symbols..."
    errors = []

    SymbolRegistry::CONFIG.each_key do |namespace|
      registry = SymbolRegistry.new(namespace)

      SymbolRegistry::CONFIG[namespace].each_key do |type|
        doc = registry.send(:load_svg, type.to_s)
        next unless doc

        symbol_ids = Set.new
        doc.css("symbol[id]").each do |symbol|
          id = symbol["id"]
          if symbol_ids.include?(id)
            errors << "Duplicate: #{namespace}/#{type} → id='#{id}'"
          else
            symbol_ids << id
          end

          symbol.css("use[href]").each do |use|
            ref_id = use["href"].sub(/^#/, "")
            unless doc.at_css("symbol[id='#{ref_id}']")
              errors << "Broken reference: #{namespace}/#{type} → '#{id}' uses '#{ref_id}', which is missing"
            end
          end
        end
      end
    end

    if errors.any?
      puts "\n⚠️  Issues detected in the SVG symbol definitions:"
      errors.each { |e| puts "  - #{e}" }
      exit(1)
    else
      puts "✔️ All symbols and references are valid."
    end
  end
end

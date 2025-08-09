# preload SVG Symbols
Rails.application.config.to_prepare do
  SymbolRegistry.preload_all!
end
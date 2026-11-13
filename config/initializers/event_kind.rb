Rails.application.config.after_initialize do
		EventKind.report_coverage! if defined?(EventKind) && defined?(Catalog::EventKinds)
end

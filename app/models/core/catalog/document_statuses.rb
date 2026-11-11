# app/models/core/catalogs/document_statuses.rb
class Catalog::DocumentStatuses < Catalog::Base
	domain "core"

	CATALOG = {
		draft:      { id: 10, order: 0, color: :grey,   icon: :draft,       editable: true,  terminal: false },
		pending:    { id: 20, order: 1, color: :amber,  icon: :pending,     editable: false, terminal: false },
		verified:   { id: 30, order: 2, color: :blue,   icon: :verified,    editable: false, terminal: false },
		active:     { id: 40, order: 3, color: :green,  icon: :yes,         editable: false, terminal: false },
		rejected:   { id: 50, order: 4, color: :red,    icon: :no,          editable: true,  terminal: false },
		superseded: { id: 60, order: 5, color: :grey,   icon: :superseded,  editable: false, terminal: true  },
		archived:   { id: 70, order: 6, color: :grey,   icon: :archived,    editable: false, terminal: true  }
	}.freeze
end

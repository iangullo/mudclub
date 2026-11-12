# app/models/core/catalogs/document_statuses.rb
class Catalog::DocumentStatuses < Catalog::Base
	domain "core"

	CATALOG = {
		draft:      {
			id: 10, order: 0, color: :grey, icon: :draft,
			editable: true,  terminal: false,
			transitions: %i[pending active archived]   # active = simple workflow shortcut
		},
		pending:    {
			id: 20, order: 1, color: :amber,  icon: :pending,
			editable: false, terminal: false,
			transitions: %i[verified rejected archived]
		},
		verified:   {
			id: 30, order: 2, color: :blue, icon: :verified,
			editable: false, terminal: false,
			transitions: %i[active rejected archived]
		},
		active:     {
			id: 40, order: 3, color: :green, icon: :yes,
			editable: false, terminal: false,
			transitions: %i[superseded archived]     # superseded set by activate! of a sibling
		},
		rejected:   {
			id: 50, order: 4, color: :red, icon: :no,
			editable: true,  terminal: false,
			transitions: %i[draft pending archived]
		},
		superseded: {
			id: 60, order: 5, color: :grey, icon: :superseded,
			editable: false, terminal: true,
			transitions: %i[archived]
		},
		archived:   {
			id: 70, order: 6, color: :grey, icon: :archived,
			editable: false, terminal: true,
			transitions: %i[]
		}
	}.freeze
end

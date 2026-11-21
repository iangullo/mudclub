# app/models/core/catalog/drill_categories.rb
class Catalog::DrillCategories < Catalog::Base
	domain "sport"

	CATALOG = {
		warmup:       { id: 1 },
		offense:      { id: 2 },
		defense:      { id: 3 },
		conditioning: { id: 4 },
		briefing:     { id: 5 },
		rest:         { id: 6 },
		scouting:     { id: 7 },
		system:       { id: 8 },
		other:        { id: 100 }
	}.freeze
end

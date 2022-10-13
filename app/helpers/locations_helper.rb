module LocationsHelper
	# return icon and top of FieldsComponent
	def location_title_fields(title:)
		title_start(icon: "location.svg", title: title)
	end

	def location_show_fields(location:)
		res = location_title_fields(title: location.name)
		res << [(@location.gmaps_url and location.gmaps_url.length > 0) ? {kind: "location", url: location.gmaps_url, name: I18n.t("location.see")} : {kind: "text", value: I18n.t("location.none")}]
		res << [{kind: "icon", value: location.practice_court ? "training.svg" : "team.svg"}]
	end

	# return FieldsComponent @title for forms
	def location_form_fields(title:, location:, season: nil)
		res = location_title_fields(title:)
		res << [{kind: "text-box", key: :name, value: location.name, size: 20}]
		res << [{kind: "icon", value: "gmaps.svg"}, {kind: "text-box", key: :gmaps_url, value: location.gmaps_url, size: 20}]
		res << [{kind: "icon", value: "training.svg"}, {kind: "label-checkbox", key: :practice_court, label: I18n.t("location.train")}]
		res.last << {kind: "hidden", key: :season_id, value: season.id} if season
		res
	end

	# return grid for @locations GridComponent
	def location_grid(locations:, season: nil)
		title = [
			{kind: "normal", value: I18n.t("location.name")},
			{kind: "normal", value: I18n.t("kind.single"), align: "center"},
			{kind: "normal", value: I18n.t("location.abbr")}
		]
		title << {kind: "add", url: season ? season_locations_path(season)+"/new" : new_location_path, frame: "modal"} if current_user.admin? or current_user.is_coach?

		rows = Array.new
		locations.each { |loc|
			row = {url: edit_location_path(loc), frame: "modal", items: []}
			row[:items] << {kind: "normal", value: loc.name}
			row[:items] << {kind: "icon", value: loc.practice_court ? "training.svg" : "team.svg", align: "center"}
			if loc.gmaps_url
				row[:items] << {kind: "location", icon: "gmaps.svg", align: "center", url: loc.gmaps_url}
			else
				row[:items] << {kind: "normal", value: ""}
			end
			row[:items] << {kind: "delete", url: location_path(loc, season_id: season ? season.id : nil), name: loc.name} if current_user.admin?
			rows << row
		}
		{title: title, rows: rows}
	end
end

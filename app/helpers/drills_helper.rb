# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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
module DrillsHelper
	# specific search bar to search through drills
	def drill_search_bar(search_in:, task_id: nil, scratch: nil)
		session.delete('drill_filters') if scratch
		fields = [
			{kind: "search-text", key: :name, label: I18n.t("person.name_a"), value: session.dig('drill_filters', 'name'), size: 10},
			{kind: "search-select", key: :kind_id, label: "#{I18n.t("kind.single")}:", value: session.dig('drill_filters', 'kind_id'), options: Kind.real.pluck(:name, :id)},
			{kind: "search-select", key: :skill_id, label: I18n.t("skill.single"), value: session.dig('drill_filters', 'skill_id'), options: Skill.real.pluck(:concept, :id)}
		]
		fields << {kind: "hidden", key: :task_id, value: task_id} if task_id
		res = [[{kind: "search-combo", url: search_in, fields: fields}]]
	end

	# return icon and top of FieldsComponent
	def drill_title_fields(title:, rows: nil, cols: nil)
		title_start(icon: "drill.svg", title: title, rows: rows, cols: cols)
	end

	# return title FieldComponent definition for drill show
	def drill_show_title(title:)
		res = drill_title_fields(title: I18n.t("drill.single"))
		res.last << {kind: "link", align: "right", icon: "playbook.png", size: "20x20", url: rails_blob_path(@drill.playbook, disposition: "attachment"), label: "Playbook"} if @drill.playbook.attached?
		res << [{kind: "subtitle", value: @drill.name}, {kind: "string", value: "(" + @drill.kind.name + ")", cols: 2}]
	end

	# return title FieldComponent definition for drill show
	def drill_show_intro
		res  = [[{kind: "label", value: I18n.t("target.many")}, {kind: "lines", class: "align-top", value: @drill.drill_targets}]]
		res << [{kind: "label", value: I18n.t("drill.material")}, {kind: "string", value: @drill.material}]
		res << [{kind: "label", value: I18n.t("drill.desc_a")}, {kind: "string", value: @drill.description}]
	end

	# return title FieldComponent definition for drill show
	def drill_show_explain
		[[{kind: "string", value: @drill.explanation}]]
	end

	# return tail Field Component definition for drill show
	def drill_show_tail
		res = [[{kind: "label", value: I18n.t("skill.abbr")}, {kind: "string", value: @drill.print_skills}]]
		res << [{kind: "label", value: I18n.t("drill.author")}, {kind: "string", value: @drill.coach.s_name}]
	end

	# return title FieldComponent definition for edit/new
	def drill_form_title(title:)
		res = drill_title_fields(title:)
		res << [{kind: "text-box", key: :name, value: @drill.name}, {kind: "select-collection", key: :kind_id, options: Kind.all, value: @drill.kind_id, align: "center"}]
	end

	# return title FieldComponent definition for edit/new
	def drill_form_playbook(playbook:)
		[[{kind: "upload", icon: "playbook.png", label: "Playbook", key: :playbook, value: playbook.filename}]]
	end

	# return title FieldComponent definition for edit/new
	def drill_form_data
		[
			[{kind: "label", value: I18n.t("target.many"), align: "right"}],
			[{kind: "nested-form", model: "drill", key: "drill_targets", child: DrillTarget.new(priority: @drill.drill_targets.count+1), row: "target_row", cols: 2}],
			[{kind: "label", value: I18n.t("drill.material"), align: "right"}, {kind: "text-box", key: :material, size: 40, value: @drill.material}],
			[{kind: "label", value: I18n.t("drill.desc_a"), align: "right"}, {kind: "text-area", key: :description, size: 36, lines: 2, value: @drill.description}]
		]
	end

	# returng FieldComponent to edit drill explanation
	def drill_form_explain
		[[{kind: "rich-text-area", key: :explanation, align: "left"}]]
	end

	# return title FieldComponent definition for edit/new
	def drill_form_tail
		[[
			{kind: "label", value: I18n.t("skill.abbr"), align: "right"},
			{kind: "nested-form", model: "drill", key: "skills", child: Skill.new, row: "skill_row"},
			{kind: "gap"},
			{kind: "label", value: I18n.t("drill.author"), align: "right"}, {kind: "select-collection", key: :coach_id, options: Coach.real, value: (@drill.coach_id.to_i>0) ? @drill.coach_id : (current_user.is_coach? ? current_user.coach.id : 1) }
		]]
	end

	# return grid for @drills GridComponent
	def drill_grid(drills:)
		track = {s_url: drills_path, s_filter: "drill_filters"}
		title = [
			{kind: "normal", value: I18n.t("kind.single"), align: "center", sort: (session.dig('drill_filters', 'kind_id') == "kind_id"), order_by: "kind_id"},
			{kind: "normal", value: I18n.t("drill.name"), sort: (session.dig('drill_filters', 'name') == "name"), order_by: "name"},
			{kind: "normal", value: I18n.t("drill.author"), align: "center", sort: (session.dig('drill_filters', 'coach_id') == "coach_id"), order_by: "coach_id"},
			{kind: "normal", value: I18n.t("target.many")},
			{kind: "normal", value: I18n.t("task.many")}
		]
		title << {kind: "add", url: new_drill_path, frame: "_top"} if current_user.admin? or current_user.is_coach?

		{track: track, title: title, rows: drill_rows(drills)}
	end

	private
		# get the grid rows for @drills
		def drill_rows(drills)
			rows = Array.new
			drills.each { |drill|
				row = {url: drill_path(drill), items: []}
				row[:items] << {kind: "normal", value: drill.kind.name, align: "center"}
				row[:items] << {kind: "normal", value: drill.name}
				row[:items] << {kind: "normal", value: drill.coach.s_name, align: "center"}
				row[:items] << {kind: "lines", value: drill.print_targets}
				row[:items] << {kind: "normal", value: Task.where(drill_id: drill.id).count, align: "center"}
				row[:items] << {kind: "delete", url: row[:url], name: drill.name} if current_user.admin?
				rows << row
			}
			rows
		end
end

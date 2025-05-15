# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
module DrillsHelper
	# return title FieldComponent definition for edit/new
	def drill_form_data
		[
			[
				{kind: :label, value: I18n.t("target.many"), align: "right"}
			],
			[
				{kind: :nested_form, model: "drill", key: "drill_targets", child: DrillTarget.new(priority: @drill.drill_targets.count+1), row: "target_row", cols: 2}
			],
			[
				{kind: :label, value: I18n.t("drill.material"), align: "right"},
				{kind: :text_box, key: :material, size: 40, value: @drill.material}
			],
			[
				{kind: :label, value: I18n.t("drill.desc_a"), align: "right"},
				{kind: :text_area, key: :description, size: 36, lines: 2, value: @drill.description, mandatory: {length: 7}}
			]
		]
	end

	# Definition of fields for modal editing of step diagrams
	def drill_form_diagram(form = nil)
		DiagramComponent.new(canvas: @canvas, svgdata: @step&.svgdata, form:)
	end

	# dropdown button definition to create a new Event
	def drill_form_diagram_button(step, form: nil)
		if step.class == Step # new step diagram
			if step.diagram.attached?
				return InputBoxComponent.new({kind: :image_box, value: step.diagram, width: "250", height: "250"}, form:)
			elsif step.diagram_svg.present?
				return ButtonComponent.new(kind: :edit, url: edit_diagram_drill_path(step_id: step&.id&.to_i, order: step&.order&.to_i), title: I18n.t("step.edit_diagram"), label: "", size: "50x50", frame: "modal", i_class: "max-h-10 max-w-10 m-1")
			else
				button = {kind: :add, name: "add-diagram", options: []}
				button[:options] << {label: I18n.t("sport.edit.diagram"), url: edit_diagram_drill_path(step_id: step&.id&.to_i, order: step&.order&.to_i, rdx: @rdx), data: {turbo_frame: :modal}}
				button[:options] << {label: I18n.t("status.no_file"), url: load_diagram_drill_path(step_id: step&.id&.to_i, order: step&.order&.to_i, rdx: @rdx), data: {turbo_frame: :modal}}
				return DropdownComponent.new(button)
			end
		else
			return nil
		end
	end

	# returng FieldComponent to edit drill explanation
	def drill_form_explain
		[[{kind: :rich_text_area, key: :step_explanation, align: "left"}]]
	end

	# return title FieldComponent definition for edit/new
	def drill_form_playbook(playbook:)
		[[{kind: :upload, symbol: drill_symbol("playbook", size:"20x20"), label: "Playbook", key: :playbook, value: playbook.filename}]]
	end

	# return title FieldComponent definition for drill steps form
	def drill_form_steps
		res = [
			[ {kind: :label, value: I18n.t("step.many")} ],
			[
				{kind: :nested_form, model: "drill", key: "steps", child: Step.new(drill_id: @drill.id, order: @drill.steps.count+1), row: "step_row"}
			]
		]
		res
	end

	# return title FieldComponent definition for edit/new
	def drill_form_tail
		coaches = (u_admin? ? Coach.real : (u_manager? ? u_club.coaches : [current_user.coach]))
		author  = (@drill.coach_id.to_i > 0 ? @drill.coach_id : (u_coachid || coaches.first))
		res = [
			[
				{kind: :label, value: I18n.t("skill.abbr"), align: "right"},
				{kind: :nested_form, model: "drill", key: "skills", child: Skill.new, row: "skill_row"},
				gap_field(size: 4),
				{kind: :label, value: I18n.t("drill.author") + ": ", align: "right"}
			]
		]
		if coaches.size > 1
			res.last << {kind: :select_collection, key: :coach_id, options: coaches, value: author}
		else
			res.last << {kind: :text, value: coaches.first.name, class: "inline-flex"}
			res.last << {kind: :hidden, key: :coach_id, value: coaches.first.id}
		end
		res
	end

	# return title FieldComponent definition for edit/new
	def drill_form_title(title:)
		res = drill_title_fields(title:)
		res << [{kind: :text_box, key: :name, placeholder: I18n.t("drill.default"), value: @drill.name, mandatory: {length:3}, cols: 3}]
		res << [
			gap_field,
			{kind: :text_box, key: :kind_id, options: Kind.list, value: @drill.kind_id? ? @drill.kind.name : nil, placeholder: I18n.t("kind.default"), mandatory: {length: 3}},
			gap_field(size: 2),
			{kind: :select_box, align: "left", key: :court_mode, options: drill_court_list, value: @drill.court_mode}
		]
	end

	# return grid for @drills GridComponent
	def drill_grid(drills: @drills)
		track = {s_url: drills_path(rdx: @rdx), s_filter: "drill_filters"}
		title = [
			{kind: :normal, value: I18n.t("kind.single"), align: "center", sort: (session.dig('drill_filters', 'kind_id') == "kind_id"), order_by: "kind_id"},
			{kind: :normal, value: I18n.t("season.abbr"), sort: (session.dig('drill_filters', 'season_id') == "season_id")},
			{kind: :normal, value: I18n.t("drill.name"), sort: (session.dig('drill_filters', 'name') == "name"), order_by: "name"},
		]
		title += [
			{kind: :normal, value: I18n.t("drill.author"), align: "center", sort: (session.dig('drill_filters', 'coach_id') == "coach_id"), order_by: "coach_id"},
			{kind: :normal, value: I18n.t("target.many")},
			#{kind: :normal, value: I18n.t("task.many")}
		] unless device=="mobile"

		title << button_field({kind: :add, url: new_drill_path(rdx: @rdx), frame: "_top"}) if u_manager? || u_coach?

		{track:, title:, rows: drill_rows(drills:)}
	end

	# specific search bar to search through drills
	def drill_search_bar(search_in:, task_id: nil, scratch: nil, cols: nil)
		session.delete('drill_filters') if scratch
		skind  = Task.find_by(id: task_id)&.drill&.kind_id || session.dig('drill_filters', 'kind_id')
		fields = [
			{kind: :search_select, key: :kind_id, blank: "#{I18n.t("kind.single")}:", value: skind, options: Kind.real.pluck(:name, :id)},
			{kind: :search_select, key: :season_id, placeholder: I18n.t("season.single"), value: session.dig('drill_filters', 'season_id'), options: Season.list},
			{kind: :search_text, key: :name, placeholder: I18n.t("drill.name"), value: session.dig('drill_filters', 'name'), size: 10},
			{kind: :search_text, key: :skill, placeholder: I18n.t("skill.single"), size: 14, value: session.dig('drill_filters', 'skill')},
		]
		fields << {kind: :hidden, key: :task_id, value: task_id} if task_id
		res = [{kind: :search_box, url: search_in, fields: fields, cols:}]
	end

	# return title FieldComponent definition for drill show
	def drill_show_title(title: I18n.t("drill.single"))
		res = drill_title_fields(title:, subtitle: "#{@drill.kind.name} - #{@drill.court_name}")
		if @drill.playbook.attached?
			res.first << button_field({
				kind: :link,
				align: "right",
				symbol: drill_symbol("playbook", size: "20x20"),
				url: rails_blob_path(@drill.playbook, disposition: "attachment"),
				label: "Playbook"
			})
		end
		res.last << pdf_button(drill_path(@drill, format: :pdf))
		res
	end

	# return title FieldComponent definition for drill show
	def drill_show_intro
		res  = [
			[
				{kind: :label, value: I18n.t("target.many")},
				{kind: :lines, class: "align-top", value: @drill.drill_targets}
			]
		]
		res << [
			{kind: :label, value: I18n.t("drill.material")},
			{kind: :string, value: @drill.material}
		]
		res << [
			{kind: :label, value: I18n.t("drill.desc_a")},
			{kind: :string, value: @drill.description}
		]
	end

	# return title FieldComponent definition for drill show - DEPRECATED
	def drill_show_explain
		[[{kind: :action_text, value: @drill.step_explanation&.body&.to_s}]]
	end

	# return FieldComponent definition for drill steps view
	def drill_show_steps
		res = [
			[{kind: :label, value: I18n.t("step.many"), cols: 3}],
			[{kind: :separator, cols: 3}]
		] unless @drill.steps.empty?
		canvas = @drill.court_symbol
		@drill.steps.order(:order).each do |step|
			text = step.has_text?
			diag = step.has_image? || step.has_svg?
			if text || diag
				cols = 2 if text ^ diag	# take 2 columns to show content
				item = [{kind: :label, value: step.order, align: "center"}]
				if diag
					field = {align: "left", cols:, class: "rounded align-top w-1/3"}
					if step.has_image?
						field[:kind]    = :image
						field[:value]   = step.diagram.attachment
						field[:i_class] = "m-1"
					else	# svg content to show
						field[:kind]    = :diagram
						field[:canvas]  = canvas
						field[:svgdata] = step.svgdata
						field[:css] = "w-#{cols ? '1/3' : 'full'} m-1"
					end
					item << field
				end
				item << {kind: :action_text, value: step.explanation&.body&.to_s, align: "top", cols:} if text
				res << item
				res << [{kind: :separator, cols: 3}]
			end
		end
		res
	end

	# return tail Field Component definition for drill show
	def drill_show_tail
		res = [
			[
				{kind: :label, value: I18n.t("skill.abbr")},
				{kind: :string, value: @drill.print_skills}
			]
		]
		if @drill.versions.size > 1 and u_manager?
			res.last << gap_field(rows: 2)
			res.last << button_field(
				{
					kind: :link,
					symbol: drill_symbol(variant: "versions"),
					label: I18n.t("version.many"),
					url: versions_drill_path,
					frame: "modal"
				},
				rows: 2
			)
		end
		res << [
			{kind: :label, value: I18n.t("drill.author")},
			{kind: :string, value: @drill.coach.s_name}
		]
	end

	# return icon and top of FieldsComponent
	def drill_title_fields(title:, subtitle: nil, rows: nil, cols: nil)
		title_start(icon: drill_symbol, title:, subtitle:, rows:, cols:)
	end

	# return title FieldComponent definition for drill show
	def drill_versions_title
		title_start(icon: drill_symbol(variant: "versions"), title: @drill.name, subtitle: I18n.t("version.many"))
	end

	# create table for drill versions
	def drill_versions_table
		res = [[
			{kind: :top_cell, value: I18n.t("calendar.date"), align: "center"},
			{kind: :top_cell, value: I18n.t("drill.author"), align: "center"},
			{kind: :top_cell, value: I18n.t("version.changes.many"), align: "center"}
		]]
		@drill.versions.each { |d_ver|
			v_user = User.find_by(id: d_ver.whodunnit)
			res << [
				{kind: :string, value: d_ver.created_at.localtime.strftime("%Y/%m/%d %H:%M"), align: "center", class: "border px py"},
				{kind: :string, value: v_user ? v_user.s_name : "", align: "center", class: "border px py"},
				{kind: :string, value: version_changes(d_ver), class: "border px py"}
			]
		}
		res
	end

	private
		# get the grid rows for @drills
		def drill_rows(drills:)
			rows = Array.new
			drills.each { |drill|
				row = {url: drill_path(drill, rdx: @rdx), items: []}
				row[:items] << {kind: :normal, value: drill.kind.name, align: "center"}
				row[:items] << {kind: :normal, value: drill.season_string}
				row[:items] << {kind: :normal, value: drill.name}
				unless device == "mobile"
					row[:items] << {kind: :normal, value: drill.coach.s_name, align: "center"}
					row[:items] << {kind: :lines, value: drill.print_targets}
				end
				#row[:items] << {kind: :normal, value: Task.where(drill_id: drill.id).count, align: "center"}
				row[:items] << button_field({kind: :delete, url: row[:url], name: drill.name}) if u_manager?
				rows << row
			}
			rows
		end

		# list of possible court types for select box configuration
		def drill_court_list
			@drill.sport.court_modes.map do |court|
				[ @drill.sport.court_name(court), court ]
			end
		end

		def drill_symbol(concept = "drill", variant: "default", size: nil)
			symbol_hash(concept, namespace: @drill&.sport&.name || "sport", variant:, size:)
		end

		# return a short definition of version changes
		def version_changes(d_ver)
			d_vch = nil
			d_ver.changeset.each_key { |key|
				keyst = I18n.t("version.changes.#{key}")
				d_vch = (d_vch ? "#{d_vch}, #{keyst}" : "#{keyst}") unless key=="updated_at"
			}
			return d_vch ? d_vch : I18n.t("version.changes.unknown")
		end
end

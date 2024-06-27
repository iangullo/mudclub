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
	# return title FieldComponent definition for edit/new
	def drill_form_data
		[
			[
				{kind: "label", value: I18n.t("target.many"), align: "right"}
			],
			[
				{kind: "nested-form", model: "drill", key: "drill_targets", child: DrillTarget.new(priority: @drill.drill_targets.count+1), row: "target_row", cols: 2}
			],
			[
				{kind: "label", value: I18n.t("drill.material"), align: "right"},
				{kind: "text-box", key: :material, size: 40, value: @drill.material}
			],
			[
				{kind: "label", value: I18n.t("drill.desc_a"), align: "right"},
				{kind: "text-area", key: :description, size: 36, lines: 2, value: @drill.description}
			]
		]
	end

	# returng FieldComponent to edit drill explanation
	def drill_form_explain
		[[{kind: "rich-text-area", key: :explanation, align: "left"}]]
	end

	# return title FieldComponent definition for edit/new
	def drill_form_playbook(playbook:)
		[[{kind: "upload", icon: "playbook.png", label: "Playbook", key: :playbook, value: playbook.filename}]]
	end

	# return title FieldComponent definition for edit/new
	def drill_form_tail
		coaches = (u_admin? ? Coach.real : (u_manager? ? u_club.coaches : [current_user.coach]))
		author  = (@drill.coach_id.to_i > 0 ? @drill.coach_id : (u_coachid || coaches.first))
		res = [
			[
				{kind: "label", value: I18n.t("skill.abbr"), align: "right"},
				{kind: "nested-form", model: "drill", key: "skills", child: Skill.new, row: "skill_row"},
				gap_field(size: 4),
				{kind: "label", value: I18n.t("drill.author") + ": ", align: "right"}
			]
		]
		if coaches.size > 1
			res.last << {kind: "select-collection", key: :coach_id, options: coaches, value: author}
		else
			res.last << {kind: "text", value: coaches.first.name, class: "inline-flex"}
			res.last << {kind: "hidden", key: :coach_id, value: coaches.first.id}
		end
		res
	end

	# return title FieldComponent definition for edit/new
	def drill_form_title(title:)
		res = drill_title_fields(title:)
		res << [
			{kind: "text-box", key: :name, placeholder: I18n.t("drill.default"), value: @drill.name},
			{kind: "text-box", key: :kind_id, options: Kind.list, value: @drill.kind_id? ? @drill.kind.name : nil, placeholder: I18n.t("kind.default")}
		]
	end

	# return grid for @drills GridComponent
	def drill_grid(drills: @drills)
		track = {s_url: drills_path, s_filter: "drill_filters"}
		title = [
			{kind: "normal", value: I18n.t("kind.single"), align: "center", sort: (session.dig('drill_filters', 'kind_id') == "kind_id"), order_by: "kind_id"},
			{kind: "normal", value: I18n.t("drill.name"), sort: (session.dig('drill_filters', 'name') == "name"), order_by: "name"},
			{kind: "normal", value: I18n.t("drill.author"), align: "center", sort: (session.dig('drill_filters', 'coach_id') == "coach_id"), order_by: "coach_id"}
		]
		title += [
			{kind: "normal", value: I18n.t("target.many")},
			#{kind: "normal", value: I18n.t("task.many")}
		] unless device=="mobile"

		title << button_field({kind: "add", url: new_drill_path, frame: "_top"}) if u_manager? || u_coach?

		{track:, title:, rows: drill_rows(drills:)}
	end

	# specific search bar to search through drills
	def drill_search_bar(search_in:, task_id: nil, scratch: nil, cols: nil)
		session.delete('drill_filters') if scratch
		skind  = Task.find_by(id: task_id)&.drill&.kind_id || session.dig('drill_filters', 'kind_id')
		fields = [
			{kind: "search-text", key: :name, placeholder: I18n.t("drill.name"), value: session.dig('drill_filters', 'name'), size: 10},
			{kind: "search-select", key: :kind_id, blank: "#{I18n.t("kind.single")}:", value: skind, options: Kind.real.pluck(:name, :id)},
			{kind: "search-text", key: :skill, placeholder: I18n.t("skill.single"), size: 14, value: session.dig('drill_filters', 'skill')}
		]
		fields << {kind: "hidden", key: :task_id, value: task_id} if task_id
		res = [{kind: "search-box", url: search_in, fields: fields, cols:}]
	end

	# return title FieldComponent definition for drill show
	def drill_show_title(title:)
		res = drill_title_fields(title: I18n.t("drill.single"), subtitle: @drill.name)
		if @drill.playbook.attached?
			res.first << button_field({
				kind: "link",
				align: "right",
				icon: "playbook.png",
				size: "20x20",
				url: rails_blob_path(@drill.playbook, disposition: "attachment"),
				label: "Playbook"
			})
		end
		res.last << {kind: "string", value: "(" + @drill.kind.name + ")"}
		res.last << pdf_button(drill_path(@drill, format: :pdf))
		res
	end

	# return title FieldComponent definition for drill show
	def drill_show_intro
		res  = [
			[
				{kind: "label", value: I18n.t("target.many")},
				{kind: "lines", class: "align-top", value: @drill.drill_targets}
			]
		]
		res << [
			{kind: "label", value: I18n.t("drill.material")},
			{kind: "string", value: @drill.material}
		]
		res << [
			{kind: "label", value: I18n.t("drill.desc_a")},
			{kind: "string", value: @drill.description}
		]
	end

	# return title FieldComponent definition for drill show
	def drill_show_explain
		[[{kind: "action-text", value: @drill.explanation.body.to_s}]]
	end

	# return tail Field Component definition for drill show
	def drill_show_tail
		res = [
			[
				{kind: "label", value: I18n.t("skill.abbr")},
				{kind: "string", value: @drill.print_skills}
			]
		]
		if @drill.versions.size > 1 and u_manager?
			res.last << gap_field(rows: 2)
			res.last << button_field(
				{
					kind: "link",
					icon: "drill_versions.svg",
					label: I18n.t("version.many"),
					url: versions_drill_path,
					frame: "modal"
				},
				rows: 2
			)
		end
		res << [
			{kind: "label", value: I18n.t("drill.author")},
			{kind: "string", value: @drill.coach.s_name}
		]
	end

	# return icon and top of FieldsComponent
	def drill_title_fields(title:, subtitle: nil, rows: nil, cols: nil)
		title_start(icon: "drill.svg", title:, subtitle:, rows:, cols:)
	end

	# return title FieldComponent definition for drill show
	def drill_versions_title
		title_start(icon: "drill.svg", title: @drill.name, subtitle: I18n.t("version.many"))
	end

	# create table for drill versions
	def drill_versions_table
		res = [[
			{kind: "top-cell", value: I18n.t("calendar.date"), align: "center"},
			{kind: "top-cell", value: I18n.t("drill.author"), align: "center"},
			{kind: "top-cell", value: I18n.t("version.changes.many"), align: "center"}
		]]
		@drill.versions.each { |d_ver|
			v_user = User.find_by(id: d_ver.whodunnit)
			res << [
				{kind: "string", value: d_ver.created_at.localtime.strftime("%Y/%m/%d %H:%M"), align: "center", class: "border px py"},
				{kind: "string", value: v_user ? v_user.s_name : "", align: "center", class: "border px py"},
				{kind: "string", value: version_changes(d_ver), class: "border px py"}
			]
		}
		res
	end

	private
		# get the grid rows for @drills
		def drill_rows(drills:)
			rows = Array.new
			drills.each { |drill|
				row = {url: drill_path(drill), items: []}
				row[:items] << {kind: "normal", value: drill.kind.name, align: "center"}
				row[:items] << {kind: "normal", value: drill.name}
				unless device == "mobile"
					row[:items] << {kind: "normal", value: drill.coach.s_name, align: "center"}
					row[:items] << {kind: "lines", value: drill.print_targets}
				end
				#row[:items] << {kind: "normal", value: Task.where(drill_id: drill.id).count, align: "center"}
				row[:items] << button_field({kind: "delete", url: row[:url], name: drill.name}) if u_manager?
				rows << row
			}
			rows
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

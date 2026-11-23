# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
# Training sessions
#
# app/models/calendar/event_kind/training.rb
class EventKind
	class Training < Base
		def self.slugs = %i[training train]
		def slug       = :training
		def title_rows = nil
		def show_cols  = 3
		def form_cols  = nil

		def created_notice = "#{notice(:created)} #{event.date_string}"
		def deleted_notice = "#{notice(:deleted)} #{event.date_string}"
		def updated_notice(initial, changed:)
			return I18n.t("status.no_data") unless changed
			"#{initial} #{event.date_string}"
		end

		# --- show hooks (called from EventsController#show) ---
		def show_fields(view, policy:, team: nil, cal: nil)
			t = team || self.team
			[ [ { kind: :accordion,
						title: Task.label(:plural),
						tail:  "#{I18n.t('shared.stats.total')}: #{event.work_duration}",
						objects: task_accordion(view, team: t, cal:) } ] ]
		end

		def show_targets(view, policy:, team: nil)
			res = [
				[ { kind: :side_cell, value: Target.label(:short), rows: 2 },
					view.topcell_item(Target.t_path(:focus, :values, :defense_short)),
					{ kind: :lines, value: event.def_targets, cols: 5 } ],
				[ view.topcell_item(Target.t_path(:focus, :values, :offense_short)),
					{ kind: :lines, value: event.off_targets, cols: 5 } ]
			]
			res << view.gap_row(cols: 3)
		end

		# training form is header-only; no body fields
		def form_fields(view, policy:, team: nil, new: false) = []

		# --- header (called from EventsHelper#event_header) ---
		def header_fragments(view, res:, policy:, user:, form: nil, chart: nil, cols: nil, **)
			res << [ { kind: :subtitle, value: category.name, cols: } ]
			return res if chart

			if form
				res.last << view.gap_item
				res << [ view.gap_item(1), view.string_item("#{division.name} (#{season.name})", cols: 2) ]
				res.last << workload_button(view, policy:, cols: 2, rows: 2, align: :left) if event.id
				res << [ view.gap_item(1), { kind: :side_cell, value: event.t_path(:kind, :training), cols: 2, align: :left } ]
				res << view.gap_row(cols: 8)
			elsif policy.export? && event.id
				res.first[1][:cols] = 4
				res.last << view.pdf_button(view.path_for(event, format: :pdf))
				res.last << view.gap_item
				res << [
					view.normal_button(copy_button(view, policy:), align: :left, class: "align-top px-2", rows: 2),
					view.string_item("#{division.name} (#{season.name})", cols: 5, align: :left),
					workload_button(view, policy:, align: :left, rows: 1)
				]
				res << [ { kind: :side_cell, value: event.t_path(:kind, :training), align: :left, cols: 5, class: "align-top" } ]
				res.last << view.normal_button(
					{ kind: :link, symbol: :attendance, label: Attendance.label,
						url: view.event_action_path(:attendance, event:), frame: :modal },
					align: :left, cols: 2
				) if policy.attendance?
			elsif user.is_athlete?
				res << [ view.gap_item, view.label_item(user.to_s, cols: 3) ]
			end
			res
		end

		# --- task UX (called from task_* actions) ---

		# Task add/edit/show form header — a compact event header used inside modals.
		def task_header(view, subtitle: nil)
			view.event_header(subtitle:, chart: true)
		end

		def task_accordion(view, team:, cal: nil)
			event.tasks.map do |task|
				{ url:     view.path_for(event, action: :show_task, cal:, task_id: task.id),
					turbo:   "modal",
					head:    task.headstring,
					content: FieldsComponent.new(task_show(view, task:, team:, title: nil)) }
			end
		end

		def task_show(view, task:, team:, title: true)
			res = []
			res << [
				view.symbol_item(:drill, { namespace: task.drill.sport&.name || "sport", size: "30x30" }, align: :center),
				view.label_item(task.drill.name),
				view.gap_item,
				{ kind: :icon_label, symbol: :clock, label: task.s_dur }
			] if title

			if task.drill.steps.empty?
				res << [ { kind: :text, value: task.drill.description } ]
			else
				res << [ { kind: :steps, steps: task.drill.steps, court: task.drill.court_mode } ]
			end

			if task.remarks?
				res << [ view.label_item(Task.fld(:remarks)) ]
				res << [ { kind: :action_text, value: task.remarks.body.to_s, size: 28 } ]
			end
			res
		end

		def task_form(view, task:, drill:, drills:, search_in:)
			res  = [ view.event_form_hidden_inputs(event.team_id) ]
			res += [
				[ view.topcell_item(Task.fld(:number)),
					view.topcell_item(Drill.label),
					view.topcell_item(Task.fld(:duration, :short)) ],
				[ { kind: :side_cell, value: task.order },
					{ kind: :select_load, key: :drill_id, url: search_in, options: drills, value: drill&.id },
					{ kind: :number_box, key: :duration, min: 1, max: 90, size: 3, value: task.duration } ],
				[ view.hidden_input(:task_id, task.id),
					view.hidden_input(:order,   task.order) ]
			]
		end

		def task_form_description(task:)
			return nil unless task.drill
			[ [ { kind: :string, value: task.drill.explanation.empty? ? task.drill.description : task.drill.explanation } ] ]
		end

		def task_form_remarks(view, task:)
			[ [ view.label_item(Task.fld(:remarks)) ],
				[ { kind: :rich_text_area, key: :remarks, value: task.remarks, size: 28 } ] ]
		end

		# --- workload (pure data — the one body that needs nothing extra) ---
		def workload(name)
			title = I18n.t("train.workload_by") + " " + I18n.t("#{name}.single")
			data  = {}
			event.tasks.each do |task|
				case name
				when "kind"
					k = task.drill.category.name
					data[k] = (data[k] || 0) + task.duration
				when "skill"
					task.drill.skills.each { |s| data[s.concept] = (data[s.concept] || 0) + task.duration }
				end
			end
			{ title:, data: }
		end

		# app/models/calendar/event_kind/training.rb
		def pdf(_view, pdf_context)
			pdf_context.pdf_label_text(
				label: Target.label(:plural),
				text:  event.print_targets
			)
			pdf_context.pdf_separator_line(style: "empty")

			event.tasks.each do |task|
				pdf_context.pdf_subtitle(task.headstring)
				pdf_context.pdf_rich_text(task.drill.explanation) if task.drill.explanation&.present?
				pdf_context.pdf_rich_text(task.remarks)           if task.remarks&.present?
				pdf_context.pdf_separator_line(style: "empty")
			end

			pdf_context.pdf_new_page
			pdf_context.pdf_subtitle(Attendance.label)
			event.team.athletes.by_number.each do |athlete|
				pdf_context.pdf_label_text(label: athlete.to_s(style: 3), text: "_")
			end
			pdf_context.pdf_separator_line(style: "empty")
			pdf_context.pdf_subtitle(Task.fld(:remarks))
		end

		private
			def copy_button(view, policy:)
				return nil unless policy.copy?
				{ kind: :action, symbol: view.symbol_hash(:copy, type: :button),
					label: I18n.t("shared.actions.copy"),
					url:   view.event_action_path(:copy, event:), frame: :modal }
			end

			def workload_button(view, policy:, cols: 2, rows: 1, align: :center, class: "align-top")
				view.dropdown_button(
					{ kind: :link, symbol: :pie,
						label: I18n.t("training.session.fields.workload_short"),
						name:  "show-chart",
						options: [
							{ label: Drill.fld(:kind, :short),
								url: view.event_action_path(:load_chart, event:, name: "kind"),
								data: { turbo_frame: :modal } },
							{ label: sport ? Sport.term(:skill) : Skill.label,
								url: view.event_action_path(:load_chart, event:, name: "skill"),
								data: { turbo_frame: :modal } }
						] },
					align:, class:, cols:, rows:
				)
			end
	end
end

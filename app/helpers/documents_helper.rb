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
module DocumentsHelper
	# return icon and top of fields definition
	def document_title(subtitle:)
		icon = symbol_hash(:document)
		title_start(icon:, title: @owner.s_name, subtitle:)
	end

	# return table for @documents TableComponent
	def document_table(documents: @documents)
		title  = [
			{ kind: :normal, value: Document.fld(:kind), align: :center },
			{ kind: :normal, value: Document.fld(:title) },
			{ kind: :normal, value: Document.fld(:active) }
		]
		title << normal_button({ kind: :add, url: new_path_for(@owner, :document), frame: :modal }) if @policy.new?

		rows = Array.new
		documents.each { |doc|
			url = path_for(doc)
			row = { url:, frame: :modal, items: [] }
			row[:items] << { kind: :normal, value: doc.kind_label }
			row[:items] << { kind: :normal, value: doc.title }
			row[:items] << symbol_item(:status,
															{ variant: doc.status.to_sym, title: doc.status_label },
															align: :center, class: "border px-1 py-1")
			row[:items] << normal_button({ kind: :delete, url:, name: doc.title, confirm: true }) if @policy.destroy?

			doc.allowed_transitions.each do |target|
				action = doc.action_for(target)
				next unless action

				predicate = :"#{action}?"
				next unless @policy.respond_to?(predicate) && @policy.public_send(predicate)

				row[:items] << document_button(action)
			end

			rows << row
		}
		{ title:, rows: }
	end

	def document_show
		res = document_title(subtitle: @document.title)
		res += [
			[
				gap_item,
				{ kind: :string, value: "(#{@document.kind_label})" }
			]
		]
		if @document.summary.present?
			res << [ label_item(Document.fld(:summary), cols: 3) ]
			res << [ { kind: :text, value: @document.summary, cols: 2 } ]
		end

		if @document.file.present?
			if @document.versioned?
				res.last << normal_button(document_button(:versions, frame: :modal, method: :get))
			end
			if @document.file_type == :img
				field = { kind: :image, cols: 3 }
			else
				field = { kind: :pdf, height: "50vh", width: "80vw", cols: 3 }
			end
			field[:value] = @document.file.attachment
			field[:cols]  = 3
			res << [ field ]
		end

		if @document.remarks.present?
			res << [ label_item(Document.fld(:remarks)) ]
			res << [ { kind: :text, value: @document.remarks, cols: 3 } ]
		end

		res
	end

	# return fields definition for document forms
	def document_form_fields(subtitle)
		res    = document_title(subtitle:)
		accept = @document.file_accept

		unless @document.persisted?
			res.last << hidden_input(:status, :active)
			res.last << hidden_input(:activated_at, DateTime.now)
		end

		res += [
			[
				label_item(Document.fld(:title)),
				{ kind: :text_box, key: :title, value: @document.title, placeholder: Document.fld(:title), mandatory: { length: 3 } }
			],
			[
				label_item(Document.fld(:kind)),
				{ kind: :select_box, align: :left, key: :kind, options: Document.kind_list(@owner), value: @document.kind }
			],
			[
				label_item(Document.fld(:summary)),
				{ kind: :text_area, key: :summary, value: @document.summary }
			],
			[
				upload_button(:file, Document.fld(:file), @document.file&.filename, symbol: symbol_hash(:document), accept:, cols: 3)
			],
			[
				label_item(Document.fld(:remarks), align: :right),
				{ kind: :text_area, key: :remarks, value: @document.remarks }
			]
		]
		res
	end

	def document_versions_header
		title_start(
			icon:     { concept: :document, options: { namespace: "common", size: "50x50" } },
			title:    @document.title,
			subtitle: Document.fld(:versions)
		)
	end

	def document_versions_table
		res = [ [
			topcell_item(I18n.t("calendar.date")),
			topcell_item(Document.fld(:version)),
			topcell_item(Document.fld(:status))
		] ]

		@document.siblings.order(version: :desc).each do |doc|
			res << [
				{ kind: :string, value: doc.created_at.localtime.strftime("%Y/%m/%d %H:%M"),
					align: "center", class: "border px-1 py-1" },
				{ kind: :string, value: doc.version,
					align: "center", class: "border px-1 py-1" },
				{ kind: :string, value: doc.status_label,
					align: "center", class: "border px-1 py-1" },
				{ kind: :string, value: doc.latest? ? "★" : "",
					align: "center" }
			]
		end

		res
	end

	private
		def document_button(action, frame: :_top, flip: true, method: :patch)
			act = action.to_sym
			{
				kind:   :action,
				symbol: symbol_hash(:action, variant: act, type: :button),
				title:  Document.act(act),
				label:  Document.act(act, :short),
				url:    path_for(@document, action: act),
				frame:, flip:,
				data:   { turbo_method: method }
			}
		end
end

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
		editor = @policy.edit?
		title  = [
			{ kind: :normal, value: Document.fld(:kind), align: :center },
			{ kind: :normal, value: Document.fld(:title) },
			{ kind: :normal, value: Document.fld(:active) }
		]
		title << button_field({ kind: :add, url: new_path_for(@owner, :document), frame: :modal }) if editor

		rows = Array.new
		documents.each { |doc|
			url = path_for(doc)
			row = { url:, frame: :modal, items: [] }
			row[:items] << { kind: :normal, value: doc.kind_label }
			row[:items] << { kind: :normal, value: doc.title }
			row[:items] << symbol_field(doc.active? ? :yes : :no, align: :center)
			row[:items] << button_field({ kind: :delete, url:, name: doc.title, confirm: true }) if editor
			rows << row
		}
		{ title:, rows: }
	end

	def document_show
		res = document_title(subtitle: @document.title)
		res += [
			[
				gap_field,
				{ kind: :string, value: "(#{@document.kind_label})" }
			]
		]
		if @document.summary.present?
			res << [ { kind: :label, value: Document.fld(:summary), cols: 3 } ]
			res << [ { kind: :text, value: @document.summary, cols: 3 } ]
		end

		if @document.file.present?
			if @document.file_type == :img
				field = { kind: :image }
			else
				field = { kind: :pdf, height: "50vh", width: "50vw" }
			end
			field[:value] = @document.file.attachment
			field[:cols]  = 3
			res << [ field ]
		end

		if @document.remarks.present?
			res << [ { kind: :label, value: Document.fld(:remarks) } ]
			res << [ { kind: :text, value: @document.remarks, cols: 3 } ]
		end

		res
	end

	# return fields definition for document forms
	def document_form_fields(subtitle)
		res    = document_title(subtitle:)
		accept = @document.file_accept
		res += [
			[
				{ kind: :label, value: Document.fld(:title) },
				{ kind: :text_box, key: :title, value: @document.title, placeholder: Document.fld(:title), mandatory: { length: 3 } }
			],
			[
				{ kind: :label, value: Document.fld(:kind) },
				{ kind: :select_box, align: :left, key: :kind, options: Document.kind_list(@owner), value: @document.kind }
			],
			[
				{ kind: :label, value: Document.fld(:summary) },
				{ kind: :text_area, key: :summary, value: @document.summary }
			],
			[
				{ kind: :upload, symbol: symbol_hash(:document), label: Document.fld(:file), key: :file, value: @document.file.filename, accept:, cols: 3 }
			],
			[
				{ kind: :label, value: Document.fld(:remarks), align: :right },
				{ kind: :text_area, key: :remarks, value: @document.remarks }
			]
		]
		res
	end
end

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
# frozen_string_literal: true

# Core shared component functions
class ApplicationComponent < ViewComponent::Base
	include Turbo::FramesHelper

	def initialize(tag: nil, classes: nil, **options)
		@tag = tag
		@classes = classes
		@options = options
	end

	private
		# True if the attachment has a blob whose backing file exists in the
		# storage service. Catches both "attached but blob missing" (DB inconsistency)
		# and "blob present but file gone" (storage inconsistency).
		def attachment_readable?(attachment)
			return false unless attachment.attached?
			blob = attachment.blob
			return false unless blob

			blob.service.exist?(blob.key)
		rescue StandardError
			false
		end

		# handle errors gracefully
		def handle_error(error)
			Rails.logger.error("[#{self.class.name}] #{error.class}: #{error.message}")
			Rails.logger.error(Array(error.backtrace).first(5).join("\n"))
			content_tag(:div, "A UI component failed to render.",
						class: "error-message p-2 bg-red-100 text-red-900 rounded")
		end

		# ensure symbol is correctly prepared
		def symbol_definition?(symbol)
			symbol&.is_a?(String) || symbol&.is_a?(Symbol)
		end

		# Normalize a Symbol/String into a Hash with options. Idempotent —
		# safe to call multiple times; only the first call fills missing options.
		def hashify_symbol(item)
			item[:symbol] = { concept: item[:symbol], options: {} } if symbol_definition?(item[:symbol])
			if item[:symbol]
				item[:symbol][:options] ||= {}
				item[:symbol][:options][:css]  ||= item[:css]  if item[:css].present?
				item[:symbol][:options][:size] ||= item[:size] if item[:size].present?
			end
		end

		def missing_symbol(img, size)
			render(SymbolComponent.new(:missing,
				size:  img[:size] || size,
				css:   img[:i_class],
				title: img[:title] || I18n.t("shared.messages.img_missing")
			))
		end

		# unfied renderer for icon/symbol images
		def render_image(img, size: nil)
			return if img.blank? || !img.is_a?(Hash)

			if img[:symbol]
				img[:symbol][:options][:size] ||= size if size.present?
				return render(SymbolComponent.new(img[:symbol][:concept], **img[:symbol][:options])).html_safe
			end

			source = img[:value].presence || img[:icon]
			return missing_symbol(img, size) unless source.present?

			if source.respond_to?(:attached?)
				return missing_symbol(img, size) unless attachment_readable?(source)
			end

			img[:size] ||= img[:icon].present? ? "25x25" : size.presence
			image_tag(source, size: img[:size], class: img[:i_class], title: img[:title]).html_safe
		rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError
			missing_symbol(img, size).html_safe
		end

		# Return the value of a nested attribute accessed with flexible keys
		# Accepts either multiple arguments or an array of fallback keys (symbol or string).
		def safe_attr(opts, *keys)
			return nil if opts.blank?

			keys.flatten.each do |key|
				val = opts[key.to_s]
				return val if val.present?

				val = opts[key.to_sym]
				return val if val.present?
			end
			nil
		end

		# wrappers to generate different field tags - self-explanatory
		def table_tag(controller: nil, data: nil, classes: [], **table_options)
			table_options[:class] = [ "table-auto", *classes ].join(" ")
			if data.present?
				table_options[:data] = data.present? ? data.dup : {}
				table_options[:data][:controller] = controller if controller
			elsif controller
				table_options[:data] = { controller: controller }
			end
			content_tag(:table, table_options) do
				yield
			end
		end

		def tablerow_tag(data: nil, classes: [], **row_options)
			row_options[:data]  = data if data.present?
			row_options[:class] = classes.join(" ") unless classes.empty?
			content_tag(:tr, row_options) do
				yield
			end
		end

		def tablecell_tag(item, tag: :td)
			cell_options = {}
			cell_options[:data]    = item[:data] if item[:data].present?
			cell_options[:class]   = item[:class] if item[:class].present?
			cell_options[:align]   = item[:align] if item[:align].present?
			cell_options[:rowspan] = item[:rows] if item[:rows].present?
			cell_options[:colspan] = item[:cols] if item[:cols].present?
			content_tag(tag, cell_options) do
				yield
			end
		end

		# define a unique identifier for this Component
		def unique_identifier(label = "component")
			"#{label}-#{SecureRandom.uuid}"
		end
end

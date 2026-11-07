require "test_helper"

# Named subclass so ViewComponent can derive a template name from
# self.class.name. Anonymous classes crash with nil.underscore.
class TestImageWrapper < ApplicationComponent
	def initialize(img, size = nil)
		super()
		@img  = img
		@size = size
	end

	def call
		render_image(@img, size: @size)
	end
end

class ApplicationComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def component
		@component ||= ApplicationComponent.new
	end

	# ─── safe_attr ──────────────────────────────────
	test "safe_attr finds string-keyed values" do
		assert_equal "Alice", component.send(:safe_attr, { "name" => "Alice" }, :name)
	end

	test "safe_attr finds symbol-keyed values" do
		assert_equal "Alice", component.send(:safe_attr, { name: "Alice" }, :name)
	end

	test "safe_attr returns the first present match" do
		attrs = { "first" => nil, "second" => "value" }
		assert_equal "value", component.send(:safe_attr, attrs, :first, :second)
	end

	test "safe_attr flattens nested key arrays" do
		assert_equal "Alice", component.send(:safe_attr, { name: "Alice" }, [ :other, :name ])
	end

	test "safe_attr returns nil for blank hashes" do
		assert_nil component.send(:safe_attr, {}, :name)
	end

	test "safe_attr returns nil for nil input" do
		assert_nil component.send(:safe_attr, nil, :name)
	end

	# ─── symbol_definition? ─────────────────────────
	test "symbol_definition? accepts strings" do
		assert component.send(:symbol_definition?, "person")
	end

	test "symbol_definition? accepts symbols" do
		assert component.send(:symbol_definition?, :person)
	end

	test "symbol_definition? rejects nil" do
		refute component.send(:symbol_definition?, nil)
	end

	test "symbol_definition? rejects hashes" do
		refute component.send(:symbol_definition?, { concept: :person })
	end

	test "symbol_definition? rejects arrays" do
		refute component.send(:symbol_definition?, [ :person ])
	end

	# ─── hashify_symbol ─────────────────────────────
	test "hashify_symbol converts a bare symbol into a symbol hash" do
		item = { symbol: :person }
		component.send(:hashify_symbol, item)
		assert_equal({ concept: :person, options: {} }, item[:symbol])
	end

	test "hashify_symbol preserves existing options" do
		item = { symbol: { concept: :person, options: { size: "30x30" } } }
		component.send(:hashify_symbol, item)
		assert_equal "30x30", item[:symbol][:options][:size]
	end

	test "hashify_symbol merges item css/size into symbol options" do
		item = { symbol: :person, css: "custom-class", size: "50x50" }
		component.send(:hashify_symbol, item)
		assert_equal "custom-class", item[:symbol][:options][:css]
		assert_equal "50x50", item[:symbol][:options][:size]
	end

	test "hashify_symbol is idempotent" do
		item = { symbol: :person, css: "custom-class" }
		component.send(:hashify_symbol, item)
		snapshot = item.dup
		component.send(:hashify_symbol, item)
		assert_equal snapshot, item
	end

	# ─── attachment_readable? ───────────────────────
	test "attachment_readable? returns false when nothing is attached" do
		person = Person.create!(name: "Test", surname: "User")
		refute component.send(:attachment_readable?, person.avatar)
	end

	test "attachment_readable? returns true when the blob is attached and present" do
		person = Person.create!(name: "Test", surname: "User")
		person.avatar.attach(io: StringIO.new("x"), filename: "x.png", content_type: "image/png")
		assert component.send(:attachment_readable?, person.avatar)
	end

	test "attachment_readable? returns false when the file is missing" do
		person = Person.create!(name: "Test", surname: "User")
		person.avatar.attach(io: StringIO.new("x"), filename: "x.png", content_type: "image/png")
		person.avatar.blob.service.delete(person.avatar.blob.key)
		refute component.send(:attachment_readable?, person.avatar)
	end

	test "attachment_readable? swallows service errors" do
		fake_attachment = Object.new
		def fake_attachment.attached? = true
		def fake_attachment.blob
			blob = Object.new
			def blob.service
				service = Object.new
				def service.exist?(_key) = raise StandardError, "boom"
				service
			end
			blob
		end

		refute component.send(:attachment_readable?, fake_attachment)
	end

	# ─── table helpers ──────────────────────────────
	test "table_tag renders with the given classes" do
		html = component.send(:table_tag, classes: [ "wide" ]) { "content" }
		assert_includes html, '<table class="table-auto wide">'
	end

	test "table_tag does not mutate the caller's data hash" do
		original = { turbolinks: "x" }
		component.send(:table_tag, controller: "foo", data: original) { "content" }
		assert_equal({ turbolinks: "x" }, original)
	end

	test "tablecell_tag passes through colspan and rowspan" do
		html = component.send(:tablecell_tag, { cols: 2, rows: 3 }) { "cell" }
		assert_includes html, 'colspan="2"'
		assert_includes html, 'rowspan="3"'
	end

	test "tablecell_tag omits nil attributes" do
		html = component.send(:tablecell_tag, {}) { "cell" }
		refute_includes html, "colspan"
		refute_includes html, "rowspan"
	end

	# ─── unique_identifier ──────────────────────────
	test "unique_identifier includes the label prefix" do
		assert_match(/\Abutton-/, component.send(:unique_identifier, "button"))
	end

	test "unique_identifier returns a UUID suffix" do
		id = component.send(:unique_identifier, "x")
		assert_match(/\Ax-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, id)
	end

	test "unique_identifier produces unique values" do
		ids = Array.new(5) { component.send(:unique_identifier, "x") }
		assert_equal 5, ids.uniq.size
	end

	# ─── render_image ───────────────────────────────
	test "render_image returns nil for a non-hash input" do
		# This one is safe — no view context needed since it returns early
		assert_nil component.send(:render_image, nil)
		assert_nil component.send(:render_image, "not a hash")
	end

	test "render_image renders a SymbolComponent when :symbol is given" do
		html = rendered_image({ symbol: { concept: :person, options: {} } })
		assert html.present?
	end

	test "render_image renders an image_tag when :value is a URL" do
		html = rendered_image({ value: "/path.png", size: "25x25" })
		assert_includes html, "<img"
		assert_includes html, 'src="/path.png"'
	end

	test "render_image renders the missing symbol when the URL is blank" do
		html = rendered_image({ icon: nil })
		assert html.present?
	end

	test "render_image renders the missing symbol when the attachment is not readable" do
		person = Person.create!(name: "Test", surname: "User")
		html = rendered_image({ value: person.avatar })
		assert html.present?
	end

	# ─── handle_error ───────────────────────────────
	test "handle_error returns an HTML fallback" do
		html = component.send(:handle_error, StandardError.new("boom"))
		assert_includes html, "error-message"
	end

	private
		def rendered_image(img, size: nil)
			render_inline(TestImageWrapper.new(img, size)).to_html
		end
end

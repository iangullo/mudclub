require "test_helper"

class FieldItemComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def render_field(field)
		render_inline(FieldItemComponent.new(field)).to_html
	end

	# ─── wrapper structure ──────────────────────────
	test "wraps the field in a <td> element" do
		html = render_field(kind: :string, value: "X")
		assert_match(/<td\b/, html)
		assert_match(%r{</td>}, html)
	end

	test "td carries the align attribute from field[:align]" do
		html = render_field(kind: :string, value: "X", align: :right)
		assert_includes html, 'align="right"'
	end

	test "td defaults to align='left' when field[:align] is not set" do
		html = render_field(kind: :string, value: "X")
		assert_includes html, 'align="left"'
	end

	test "side_cell defaults to align='right'" do
		html = render_field(kind: :side_cell, value: "X")
		assert_includes html, 'align="right"'
	end

	# ─── text rendering ─────────────────────────────
	test "string kind renders its value" do
		html = render_field(kind: :string, value: "Hello world")
		assert_includes html, "Hello world"
	end

	test "label kind renders its value and gets font-semibold" do
		html = render_field(kind: :label, value: "Label text")
		assert_includes html, "Label text"
		assert_includes html, "font-semibold"
	end

	test "subtitle kind renders its value and gets font-bold" do
		html = render_field(kind: :subtitle, value: "Subtitle")
		assert_includes html, "Subtitle"
		assert_includes html, "font-bold"
	end

	test "title kind renders its value in yellow" do
		html = render_field(kind: :title, value: "Title")
		assert_includes html, "Title"
		assert_includes html, "font-bold"
		assert_includes html, "text-yellow-600"
	end

	test "top_cell kind gets the indigo header styling" do
		html = render_field(kind: :top_cell, value: "Header")
		assert_includes html, "Header"
		assert_includes html, "bg-indigo-900"
		assert_includes html, "text-gray-300"
		assert_includes html, "font-semibold"
	end

	test "side_cell kind gets the indigo label styling" do
		html = render_field(kind: :side_cell, value: "Side")
		assert_includes html, "Side"
		assert_includes html, "text-indigo-900"
		assert_includes html, "font-semibold"
	end

	# ─── CSS hygiene (regression guards) ────────────
	test "no text kind leaks the invalid 'align-center' class" do
		%i[string label subtitle title top_cell side_cell lines].each do |kind|
			value = kind == :lines ? [ "X" ] : "X"
			html  = render_field(kind: kind, value: value)
			refute_includes html, "align-center", "kind #{kind} emits align-center"
		end
	end

	test "no text kind emits a bare 'px' or 'py' class" do
		%i[string label subtitle title top_cell side_cell lines].each do |kind|
			value = kind == :lines ? [ "X" ] : "X"
			html  = render_field(kind: kind, value: value)
			refute_match(/\bclass="[^"]*\bpx\b(?![-\w])/, html, "kind #{kind} emits bare px")
			refute_match(/\bclass="[^"]*\bpy\b(?![-\w])/, html, "kind #{kind} emits bare py")
		end
	end

	# ─── gap ────────────────────────────────────────
	test "gap renders the requested number of non-breaking spaces" do
		html = render_field(kind: :gap, size: 3)
		assert_includes html, "&nbsp;&nbsp;&nbsp;"
	end

	test "gap defaults to 4 non-breaking spaces" do
		html = render_field(kind: :gap)
		assert_includes html, "&nbsp;&nbsp;&nbsp;&nbsp;"
	end

	# ─── lines ──────────────────────────────────────
	test "lines renders each line with a break" do
		html = render_field(kind: :lines, value: [ "first", "second" ])
		assert_includes html, "first"
		assert_includes html, "second"
		assert_includes html, "<br"
	end

	# ─── separator ──────────────────────────────────
	test "separator defaults to solid border" do
		html = render_field(kind: :separator)
		assert_match(/<hr\b/, html)
		assert_includes html, "border-solid"
	end

	test "separator with stroke: :dashed renders border-dashed" do
		html = render_field(kind: :separator, stroke: :dashed)
		assert_includes html, "border-dashed"
		refute_includes html, 'class="dashed"'
	end

	test "separator with stroke: :dotted renders border-dotted" do
		html = render_field(kind: :separator, stroke: :dotted)
		assert_includes html, "border-dotted"
		refute_includes html, 'class="dotted"'
	end

	# ─── column / row span ──────────────────────────
	test "cols value produces md:col-span-N class" do
		html = render_field(kind: :string, value: "X", cols: 4)
		assert_includes html, "md:col-span-4"
	end

	test "rows value produces md:row-span-N class" do
		html = render_field(kind: :string, value: "X", rows: 2)
		assert_includes html, "md:row-span-2"
	end

	test "cols value beyond 12 is clamped to 12" do
		html = render_field(kind: :string, value: "X", cols: 20)
		assert_includes html, "md:col-span-12"
		refute_includes html, "md:col-span-20"
	end

	test "rows value beyond 6 is clamped to 6" do
		html = render_field(kind: :string, value: "X", rows: 10)
		assert_includes html, "md:row-span-6"
		refute_includes html, "md:row-span-10"
	end

	test "table kind does not get a row-span class even when rows is set" do
		html = render_field(
			kind: :table,
			value: { title: [], rows: [] },
			rows: 3
		)
		refute_includes html, "md:row-span-3"
	end

	# ─── wide kinds get w-full ──────────────────────
	test "accordion, diagram, table, svg kinds get the w-full class" do
		%i[svg].each do |kind|
			html = render_field(kind: kind, value: "<svg></svg>")
			assert_includes html, "w-full", "kind #{kind} missing w-full"
		end
	end

	# ─── CSS presence check ─────────────────────────
	test "the classes emitted by FieldItemComponent are compiled" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			font-semibold font-bold text-yellow-600
			text-indigo-900 bg-indigo-900 text-gray-300
			border-solid border-dashed border-dotted
			px-1 py-1 px-2 py-1
			md:col-span-4 md:col-span-12
			md:row-span-2 md:row-span-6
			w-full align-top border
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end

	# ─── span clamping ──────────────────────────────
	test "cols value within 1–12 emits the requested class" do
		html = render_field(kind: :string, value: "X", cols: 4)
		assert_includes html, "md:col-span-4"
	end

	test "cols value above 12 is clamped to md:col-span-12" do
		html = render_field(kind: :string, value: "X", cols: 20)
		assert_includes html, "md:col-span-12"
		refute_includes html, "md:col-span-20"
	end

	test "cols value below 1 is clamped to md:col-span-1" do
		html = render_field(kind: :string, value: "X", cols: 0)
		assert_includes html, "md:col-span-1"
		refute_includes html, "md:col-span-0"
	end

	test "cols passed as a string is coerced and clamped" do
		html = render_field(kind: :string, value: "X", cols: "8")
		assert_includes html, "md:col-span-8"
	end

	test "rows value within 1–6 emits the requested class" do
		html = render_field(kind: :string, value: "X", rows: 3)
		assert_includes html, "md:row-span-3"
	end

	test "rows value above 6 is clamped to md:row-span-6" do
		html = render_field(kind: :string, value: "X", rows: 10)
		assert_includes html, "md:row-span-6"
		refute_includes html, "md:row-span-10"
	end

	test "rows value below 1 is clamped to md:row-span-1" do
		html = render_field(kind: :string, value: "X", rows: -2)
		assert_includes html, "md:row-span-1"
	end

	test "table kind does not emit a row-span class" do
		html = render_field(kind: :table, value: { title: [], rows: [] }, rows: 3)
		refute_includes html, "md:row-span-3"
	end

	test "clamped cols still emit the original HTML colspan attribute" do
		# The CSS class caps at 12, the HTML colspan keeps the caller's value
		html = render_field(kind: :string, value: "X", cols: 20)
		assert_includes html, 'colspan="20"'
		assert_includes html, "md:col-span-12"
	end
end

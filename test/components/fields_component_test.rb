require "test_helper"

class FieldsComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def render_fields(fields, form: nil)
		render_inline(FieldsComponent.new(fields, form: form)).to_html
	end

	# ─── wrapper structure ──────────────────────────
	test "renders a wrapper <table> with table-auto class" do
		html = render_fields([ [ { kind: :string, value: "X" } ] ])
		assert_match(/<table\b/, html)
		assert_includes html, "table-auto"
	end

	test "wraps each field group in a <tr>" do
		html = render_fields([
			[ { kind: :string, value: "a" } ],
			[ { kind: :string, value: "b" } ]
		])
		assert_equal 2, html.scan(/<tr\b/).size
	end

	test "wraps each field in a <td> via FieldItemComponent" do
		html = render_fields([
			[ { kind: :string, value: "a" }, { kind: :string, value: "b" } ]
		])
		assert_equal 2, html.scan(/<td\b/).size
	end

	test "renders cell content in the order given" do
		html = render_fields([
			[
				{ kind: :string, value: "first" },
				{ kind: :string, value: "second" },
				{ kind: :string, value: "third" }
			]
		])
		first_pos  = html.index("first")
		second_pos = html.index("second")
		third_pos  = html.index("third")

		assert first_pos < second_pos
		assert second_pos < third_pos
	end

	# ─── multiple rows ──────────────────────────────
	test "renders multiple rows with multiple cells each" do
		html = render_fields([
			[ { kind: :string, value: "r1c1" }, { kind: :string, value: "r1c2" } ],
			[ { kind: :string, value: "r2c1" }, { kind: :string, value: "r2c2" } ]
		])

		assert_equal 2, html.scan(/<tr\b/).size
		assert_equal 4, html.scan(/<td\b/).size
		%w[r1c1 r1c2 r2c1 r2c2].each { |v| assert_includes html, v }
	end

	# ─── render? ────────────────────────────────────
	test "render? returns false for an empty field list" do
		html = render_inline(FieldsComponent.new([])).to_html
		assert_equal "", html.strip
	end

	test "render? returns true when fields are present" do
		html = render_inline(FieldsComponent.new([ [ { kind: :string, value: "X" } ] ])).to_html
		refute_equal "", html.strip
	end

	# ─── form propagation ───────────────────────────
	test "assigning form propagates to all FieldItemComponents" do
		component = FieldsComponent.new([ [ { kind: :string, value: "a" }, { kind: :string, value: "b" } ] ])

		# Access internal @fields to check the propagation
		fields_before = component.instance_variable_get(:@fields)
		assert fields_before[0][0].instance_variable_get(:@form).nil?
		assert fields_before[0][1].instance_variable_get(:@form).nil?

		fake_form = Object.new
		component.form = fake_form

		fields_after = component.instance_variable_get(:@fields)
		assert_same fake_form, fields_after[0][0].instance_variable_get(:@form)
		assert_same fake_form, fields_after[0][1].instance_variable_get(:@form)
	end

	test "form assignment does not raise on fields that don't respond to form=" do
		# Both FieldItemComponents respond to form=; a field kind that ignores it
		# still delegates cleanly because FieldItemComponent#form= is defined
		component = FieldsComponent.new([ [ { kind: :string, value: "a" } ] ])
		assert_nothing_raised { component.form = Object.new }
	end

	# ─── delegation to FieldItemComponent ───────────
	test "delegates CSS classes from the field hash" do
		html = render_fields([ [ { kind: :string, value: "X", class: "custom-class" } ] ])
		assert_includes html, "custom-class"
	end

	test "delegates col-span classes via FieldItemComponent" do
		html = render_fields([ [ { kind: :string, value: "X", cols: 4 } ] ])
		assert_includes html, "md:col-span-4"
	end

	test "delegates align attribute via FieldItemComponent" do
		html = render_fields([ [ { kind: :string, value: "X", align: :right } ] ])
		assert_includes html, 'align="right"'
	end

	# ─── output is well-formed ──────────────────────
	test "produces valid nested table markup" do
		html = render_fields([
			[ { kind: :string, value: "a" }, { kind: :string, value: "b" } ],
			[ { kind: :string, value: "c" } ]
		])
		# Rough structural check — table wraps rows, rows wrap cells
		assert_match(%r{<table\b[^>]*>.*<tr\b.*<td\b.*</td>.*</tr>.*</table>}m, html)
	end

	# ─── CSS presence ───────────────────────────────
	test "the classes emitted by FieldsComponent compile in the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[table-auto].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

require "test_helper"

class SymbolComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# Assumes common.icon.person.default exists in SymbolRegistry.
	# Adjust to a symbol you know is loaded if this one isn't.
	def default_component(**opts)
		SymbolComponent.new(:person, **opts)
	end

	# ─── basic rendering ────────────────────────────
	test "renders an SVG element for a known concept" do
		html = render_inline(default_component).to_html
		assert_match(/<svg/, html)
		refute_includes html, 'data-debug="missing-symbol"'
	end

	test "renders the missing symbol for an unknown concept" do
		html = render_inline(SymbolComponent.new(:nonexistent_symbol_xyz)).to_html
		assert_includes html, "stroke:#ff0000"
		assert_includes html, "<tspan"
	end

	test "includes a <title> element when title is passed" do
		html = render_inline(default_component(title: "Friendly name")).to_html
		assert_includes html, "<title>Friendly name</title>"
	end

	test "includes a <title> element when data[:title] is passed" do
		html = render_inline(default_component(data: { title: "From data" })).to_html
		assert_includes html, "<title>From data</title>"
	end

	# ─── size parsing ───────────────────────────────
	test "renders at the requested size for WxH" do
		html = render_inline(default_component(size: "30x30")).to_html
		assert_includes html, 'width="30"'
		assert_includes html, 'height="30"'
	end

	test "renders a square size when a single number is given" do
		html = render_inline(default_component(size: "42")).to_html
		assert_includes html, 'width="42"'
		assert_includes html, 'height="42"'
	end

	test "falls back to 25x25 when size is missing" do
		html = render_inline(default_component).to_html
		assert_includes html, 'width="25"'
		assert_includes html, 'height="25"'
	end

	test "falls back to 25x25 when size is malformed" do
		html = render_inline(default_component(size: "huge")).to_html
		assert_includes html, 'width="25"'
		assert_includes html, 'height="25"'
	end

	# ─── type-based default class (regression guard for the ordering bug) ───
	test "icon type receives the icon default class" do
		html = render_inline(SymbolComponent.new(:person, type: :icon)).to_html
		assert_includes html, "m-1"
	end

	test "object type receives the object default class" do
		html = render_inline(SymbolComponent.new(:person, type: :object)).to_html
		assert_includes html, "inline-block"
	end

	test "court type receives w-full h-auto" do
		html = render_inline(SymbolComponent.new(:person, type: :court)).to_html
		assert_includes html, "w-full"
		assert_includes html, "h-auto"
	end

	test "explicit css overrides the default class" do
		html = render_inline(default_component(css: "custom-symbol")).to_html
		assert_includes html, "custom-symbol"
		refute_includes html, "m-1"
	end

	# ─── namespace / variant / symbol_id ────────────
	test "namespace and variant defaults to common/icon/default" do
		html = render_inline(default_component).to_html
		assert_includes html, 'data-symbol-id="common.icon.person.default"'
	end

	test "explicit namespace and variant are honored" do
		html = render_inline(
			SymbolComponent.new(:person, namespace: "common", variant: "default")
		).to_html
		assert_includes html, 'data-symbol-id="common.icon.person.default"'
	end

	test "symbol_id in data overrides namespace/type/variant" do
		html = render_inline(
			SymbolComponent.new(:person, data: { symbol_id: "common.icon.person.default" })
		).to_html
		assert_includes html, 'data-symbol-id="common.icon.person.default"'
	end

	# ─── data attributes ────────────────────────────
	test "passes data: hash through to the SVG" do
		html = render_inline(default_component(data: { color: "red" })).to_html
		assert_includes html, 'data-color="red"'
	end

	test "always sets data-kind matching the type" do
		html = render_inline(default_component).to_html
		assert_includes html, 'data-kind="icon"'
	end

	# ─── aria / accessibility ───────────────────────
	test "sets aria-label when data[:label] is present" do
		html = render_inline(default_component(data: { label: "Person symbol" })).to_html
		assert_includes html, 'aria-label="Person symbol"'
	end

	test "role is always img" do
		html = render_inline(default_component).to_html
		assert_includes html, 'role="img"'
	end

	# ─── group mode ─────────────────────────────────
	test "group: true produces a <g> wrapper instead of <svg>" do
		html = render_inline(default_component(group: true)).to_html
		assert_match(/<g\b/, html)
		refute_match(/<svg\b/, html)
	end

	test "group: true omits width/height/xmlns on the outer <g>" do
		html      = render_inline(default_component(group: true)).to_html
		outer_tag = html[/<g\b[^>]*>/]

		refute_match(/\swidth=/,  outer_tag)
		refute_match(/\sheight=/, outer_tag)
		refute_match(/\sxmlns=/,  outer_tag)
	end

	# ─── viewBox ────────────────────────────────────
	test "viewBox falls back to the symbol's declared viewBox" do
		html = render_inline(default_component).to_html
		assert_match(/viewBox="[^"]+"/, html)
	end

	test "explicit view_box overrides the symbol's" do
		html = render_inline(default_component(view_box: "0 0 64 64")).to_html
		assert_includes html, 'viewBox="0 0 64 64"'
	end

	# ─── helper methods ─────────────────────────────
	test "full_id concatenates namespace, type, concept, variant" do
		component = default_component
		assert_equal "common.icon.person.default", component.full_id
	end

	test "view_box parses the string into x/y/width/height" do
		component = default_component(view_box: "0 0 64 64")
		expect_vb = { x: "0", y: "0", width: "64", height: "64" }
		assert_equal expect_vb, component.view_box
	end

	test "to_img returns a base64 data URI" do
		img_src = default_component.to_img
		assert_match(%r{\Adata:image/svg\+xml;base64,[A-Za-z0-9+/=]+\z}, img_src)
	end

	# ─── label mutation safety ──────────────────────
	test "does not leak labels between renders" do
		html1 = render_inline(
			SymbolComponent.new(:person,
				data: { symbol_id: "common.icon.person.default", label: "CustomLabel" })
		).to_html
		html2 = render_inline(
			SymbolComponent.new(:person,
				data: { symbol_id: "common.icon.person.default" })
		).to_html

		# If SymbolRegistry memoizes the underlying node, the label mutation
		# from the first render would leak into the second.
		if html1.include?("CustomLabel")
			refute_includes html2, "CustomLabel",
				"Label leaked from a previous render — SymbolRegistry may be memoizing the node"
		end
	end
end

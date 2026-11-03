require "test_helper"

class DropdownComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def simple_button(**overrides)
		{
			kind: :add,
			name: "test-dropdown",
			options: [
				{ label: "First",  url: "/first"  },
				{ label: "Second", url: "/second" }
			]
		}.merge(overrides)
	end

	# ─── basic structure ────────────────────────────
	test "renders a toggle button" do
		html = render_inline(DropdownComponent.new(simple_button)).to_html
		assert_includes html, "<button"
		assert_includes html, 'id="test-dropdown-btn"'
		assert_includes html, 'data-dropdown-toggle="test-dropdown"'
	end

	test "renders a menu container" do
		html = render_inline(DropdownComponent.new(simple_button)).to_html
		assert_includes html, 'id="test-dropdown"'
		assert_includes html, 'aria-labelledby="test-dropdown-btn"'
	end

	test "renders one link per option" do
		html = render_inline(DropdownComponent.new(simple_button)).to_html
		assert_includes html, 'href="/first"'
		assert_includes html, 'href="/second"'
		assert_includes html, "First"
		assert_includes html, "Second"
	end

	test "main menu uses bottom-start placement" do
		html = render_inline(DropdownComponent.new(simple_button)).to_html
		assert_includes html, 'data-dropdown-placement="bottom-start"'
	end

	test "nested menu uses right-start placement" do
		html = render_inline(
			DropdownComponent.new(
				kind: :menu, name: "outer", label: "Outer",
				options: [ { name: "inner", kind: :menu, label: "Inner",
										options: [ { label: "Deep", url: "/deep" } ] } ]
			)
		).to_html
		assert_includes html, 'data-dropdown-placement="right-start"'
	end

	# ─── kind-based styling ─────────────────────────
	test "add kind uses green hover classes" do
		html = render_inline(DropdownComponent.new(simple_button(kind: :add))).to_html
		assert_includes html, "hover:bg-green-200"
		assert_includes html, "focus:ring-green-500"
	end

	test "menu kind uses blue hover classes" do
		html = render_inline(
			DropdownComponent.new(
				kind: :menu, name: "test-menu", label: "Menu",
				options: [ { label: "Opt", url: "/opt" } ]
			)
		).to_html
		assert_includes html, "hover:bg-blue-700"
	end

	test "link kind uses gray hover classes" do
		html = render_inline(
			DropdownComponent.new(
				kind: :link, name: "test-link", url: "/x", label: "Go",
				options: [ { label: "Opt", url: "/opt" } ]
			)
		).to_html
		assert_includes html, "hover:bg-gray-300"
	end

	# ─── rendering variants ─────────────────────────
	test "hamburger variant renders the hamburger SVG" do
		html = render_inline(
			DropdownComponent.new(
				kind: :menu, name: "ham", ham: true,
				options: [ { label: "Opt", url: "/opt" } ]
			)
		).to_html
		assert_includes html, "M4 6h16M4 12h16M4 18h16"
	end

	test "symbol is rendered when provided" do
		html = render_inline(
			DropdownComponent.new(
				kind: :add, name: "sym-add",
				symbol: :add,
				options: [ { label: "Opt", url: "/opt" } ]
			)
		).to_html
		assert_match(/<svg/, html)
	end

	test "label is rendered when not appended" do
		html = render_inline(
			DropdownComponent.new(
				kind: :menu, name: "lbl", label: "Choose",
				options: [ { label: "Opt", url: "/opt" } ]
			)
		).to_html
		assert_includes html, "Choose"
	end

	# ─── nested dropdowns ───────────────────────────
	test "nested options render a nested DropdownComponent" do
		html = render_inline(
			DropdownComponent.new(
				kind: :menu, name: "outer", label: "Outer",
				options: [
					{ name: "inner", kind: :menu, label: "Inner",
						options: [ { label: "Deep", url: "/deep" } ] }
				]
			)
		).to_html
		assert_includes html, 'href="/deep"'
		assert_includes html, 'data-dropdown-toggle="inner"'
	end

	# ─── option symbols (regression guard for template bug #2) ───
	test "per-option symbols are rendered using the option's symbol, not the button's" do
		html = render_inline(
			DropdownComponent.new(
				kind: :add, name: "symbols",
				symbol: :add,
				options: [
					{ label: "Train", url: "/train", symbol: :training },
					{ label: "Match", url: "/match", symbol: :match }
				]
			)
		).to_html

		# The button's :add symbol renders once (in the button itself).
		# Each option renders its own symbol; if the template bug is present,
		# :add would appear three times instead of once.
		assert_equal 1, html.scan(/data-symbol-id="[^"]*\.add\./).size,
			"Expected :add symbol to render once (in the button); template bug is rendering it in options too"
		assert_includes html, "training"
		assert_includes html, "match"
	end

	# ─── CSS presence ───────────────────────────────
	test "dropdown classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			inline-flex items-center whitespace-nowrap rounded-md
			hover:bg-green-200 focus:bg-green-200 focus:ring-green-500
			hover:bg-blue-700 focus:ring-gray-200
			hover:bg-gray-300 focus:ring-gray-300 focus:border-gray-300
			bg-gray-200 text-gray-500 bg-blue-900 bg-gray-100
			hidden overflow-hidden p-2 font-semibold
			block m-0 no-underline
			h-6 w-6 h-4 w-4 ml-2 ml-3
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls}"
		end
	end
end

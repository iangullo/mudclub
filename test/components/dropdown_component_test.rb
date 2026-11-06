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

	def nested_button(**overrides)
		{
			kind: :menu, name: "outer", label: "Outer",
			options: [
				{
					name: "inner", kind: :menu, label: "Inner",
					options: [ { label: "Deep", url: "/deep" } ]
				}
			]
		}.merge(overrides)
	end

	# ─── structural wiring (replaces Flowbite assertions) ───
	test "renders a toggle button with a Stimulus trigger target" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		button = fragment.at_css("button")
		refute_nil button
		assert_equal "test-dropdown-btn", button["id"]
		assert_equal "trigger", button["data-dropdown-target"]
		assert_equal "click->dropdown#toggle", CGI.unescapeHTML(button["data-action"])
		assert_equal "button", button["type"]
	end

	test "renders a menu container with a Stimulus menu target" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		menu = fragment.at_css("[data-dropdown-target='menu']")
		refute_nil menu
		assert_equal "test-dropdown", menu["id"]
		assert_includes menu["class"], "hidden"
	end

	test "trigger and menu share the same data-controller root" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		root = fragment.at_css("[data-controller='dropdown']")
		refute_nil root
		assert_not_nil root.at_css("[data-dropdown-target='trigger']"),
			"trigger must be inside the dropdown controller wrapper"
		assert_not_nil root.at_css("[data-dropdown-target='menu']"),
			"menu must be inside the dropdown controller wrapper"
	end

	test "non-append wrapper is relative and inline-block" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		root = fragment.at_css("[data-controller='dropdown']")
		assert_includes root["class"], "relative"
		assert_includes root["class"], "inline-block"
		refute_includes root["class"], "inline-flex"
	end

	test "append wrapper is relative and inline-flex" do
		fragment = render_inline(DropdownComponent.new(
			simple_button(append: true, label: "Filter", symbol: :add)
		))
		root = fragment.at_css("[data-controller='dropdown']")
		assert_includes root["class"], "relative"
		assert_includes root["class"], "inline-flex"
		assert_includes root["class"], "items-center"
	end

	test "aria-labelledby points at the trigger id" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		ul = fragment.at_css("ul")
		assert_equal "test-dropdown-btn", ul["aria-labelledby"]
	end

	# ─── Flowbite removal guard ─────────────────────
	test "no Flowbite attributes are emitted" do
		html = render_inline(DropdownComponent.new(simple_button)).to_html
		refute_includes html, "data-dropdown-toggle"
		refute_includes html, "data-dropdown-placement"
		refute_includes html, "data-dropdown-offset-distance"
		refute_includes html, "data-dropdown-offset-skidding"
	end

	# ─── placement via static classes ───────────────
	test "top-level menu carries bottom-start placement classes" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		menu = fragment.at_css("[data-dropdown-target='menu']")
		assert_includes menu["class"], "top-full"
		assert_includes menu["class"], "left-0"
		assert_includes menu["class"], "mt-1"
	end

	test "nested menu carries right-start placement classes" do
		fragment = render_inline(DropdownComponent.new(nested_button))
		inner = fragment.at_css("#inner")
		refute_nil inner
		assert_includes inner["class"], "left-full"
		assert_includes inner["class"], "top-0"
		assert_includes inner["class"], "ml-1"
		refute_includes inner["class"], "top-full",
			"nested menu must not use top-level placement"
	end

	test "menu kind has absolute positioning (regression: Flowbite used to add this)" do
		fragment = render_inline(DropdownComponent.new(
			kind: :menu, name: "m", label: "M",
			options: [ { label: "x", url: "/x" } ]
		))
		menu = fragment.at_css("[data-dropdown-target='menu']")
		assert_includes menu["class"], "absolute"
	end

	# ─── link rendering ─────────────────────────────
	test "renders one link per option" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		links = fragment.css("a")
		assert_equal 2, links.size
		assert_equal [ "/first", "/second" ], links.map { |a| a["href"] }
		assert_includes fragment.to_html, "First"
		assert_includes fragment.to_html, "Second"
	end

	# ─── kind-based styling ─────────────────────────
	test "add kind uses green hover classes" do
		html = render_inline(DropdownComponent.new(simple_button(kind: :add))).to_html
		assert_includes html, "hover:bg-green-200"
		assert_includes html, "focus:ring-green-500"
	end

	test "menu kind uses blue hover classes" do
		html = render_inline(DropdownComponent.new(
			kind: :menu, name: "test-menu", label: "Menu",
			options: [ { label: "Opt", url: "/opt" } ]
		)).to_html
		assert_includes html, "hover:bg-blue-700"
	end

	test "link kind uses gray hover classes" do
		html = render_inline(DropdownComponent.new(
			kind: :link, name: "test-link", url: "/x", label: "Go",
			options: [ { label: "Opt", url: "/opt" } ]
		)).to_html
		assert_includes html, "hover:bg-gray-300"
	end

	test "link items do not wrap" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		links = fragment.css("a")
		refute_empty links
		links.each do |a|
			assert_includes a["class"], "whitespace-nowrap",
				"link labels must not wrap — otherwise the menu caps at trigger width"
		end
	end

	test "link items align icon and label on one row" do
		fragment = render_inline(DropdownComponent.new(simple_button))
		a = fragment.at_css("a")
		assert_includes a["class"], "flex"
		assert_includes a["class"], "items-center"
	end

	# ─── rendering variants ─────────────────────────
	test "hamburger variant renders the hamburger SVG" do
		html = render_inline(DropdownComponent.new(
			kind: :menu, name: "ham", ham: true,
			options: [ { label: "Opt", url: "/opt" } ]
		)).to_html
		assert_includes html, "M4 6h16M4 12h16M4 18h16"
	end

	test "symbol is rendered when provided" do
		html = render_inline(DropdownComponent.new(
			kind: :add, name: "sym-add", symbol: :add,
			options: [ { label: "Opt", url: "/opt" } ]
		)).to_html
		assert_match(/<svg/, html)
	end

	test "label is rendered when not appended" do
		html = render_inline(DropdownComponent.new(
			kind: :menu, name: "lbl", label: "Choose",
			options: [ { label: "Opt", url: "/opt" } ]
		)).to_html
		assert_includes html, "Choose"
	end

	test "append renders the label outside the button" do
		fragment = render_inline(DropdownComponent.new(
			simple_button(append: true, label: "Filter", symbol: :add)
		))
		button = fragment.at_css("button")
		refute_nil button
		refute_includes button.text, "Filter",
			"append label must live outside the trigger button"
		root = fragment.at_css("[data-controller='dropdown']")
		assert_includes root.text, "Filter"
	end

	# ─── recursion ──────────────────────────────────
	test "nested dropdown renders its own dropdown controller wrapper" do
		fragment = render_inline(DropdownComponent.new(nested_button))
		wrappers = fragment.css("[data-controller='dropdown']")
		assert_equal 2, wrappers.size,
			"outer and inner dropdowns must each have their own controller root"
	end

	test "nested dropdown has its own trigger and menu targets" do
		html = render_inline(DropdownComponent.new(nested_button)).to_html
		assert_equal 2, html.scan('data-dropdown-target="trigger"').size
		assert_equal 2, html.scan('data-dropdown-target="menu"').size
	end

	test "nested options render deep links" do
		html = render_inline(DropdownComponent.new(nested_button)).to_html
		assert_includes html, 'href="/deep"'
	end

	test "inner menu is a DOM descendant of the outer menu" do
		fragment = render_inline(DropdownComponent.new(nested_button))
		inner = fragment.at_css("#inner")
		outer_menu = fragment.at_css("#outer")
		assert inner.ancestors.include?(outer_menu),
			"inner menu must sit inside the outer menu so Stimulus target scoping resolves to the outer menu first"
	end

	test "each dropdown in a nested pair is independently wired" do
		fragment = render_inline(DropdownComponent.new(nested_button))
		triggers = fragment.css("[data-dropdown-target='trigger']")
		triggers.each do |t|
			assert_equal "click->dropdown#toggle", CGI.unescapeHTML(t["data-action"]),
				"every trigger must wire to the dropdown controller"
		end
	end

	# ─── per-option symbols (regression guard) ──────
	test "per-option symbols render with the option's symbol, not the button's" do
		html = render_inline(DropdownComponent.new(
			kind: :add, name: "symbols", symbol: :add,
			options: [
				{ label: "Train", url: "/train", symbol: :training },
				{ label: "Match", url: "/match", symbol: :match }
			]
		)).to_html

		assert_equal 1, html.scan(/data-symbol-id="[^"]*\.add\./).size,
			"Expected :add symbol to render once (button); template bug would render it 3×"
		assert_includes html, "training"
		assert_includes html, "match"
	end

	# ─── CSS compilation guard ──────────────────────
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
			relative inline-block absolute z-10
			top-full left-0 mt-1
			left-full top-0 ml-1
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

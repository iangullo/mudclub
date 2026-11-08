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

	# ─── trigger initial state ───────────────────────
	test "trigger starts with aria-expanded false" do
			button = render_inline(DropdownComponent.new(simple_button)).at_css("button")
			assert_equal "false", button["aria-expanded"],
					"Stimulus derives isOpen from this attribute — must start false"
	end

	test "hamburger trigger carries hover styling" do
			button = render_inline(DropdownComponent.new(
					kind: :menu, name: "ham", ham: true,
					options: [ { label: "Opt", url: "/opt" } ]
			)).at_css("button")
			assert_includes button["class"], "hover:bg-blue-700",
					"hamburger trigger must have hover feedback — regression: mobile/hamburger had no hover"
	end

	# ─── placement decisions ─────────────────────────
	test "align: :right flips top-level menu to bottom-end" do
			menu = render_inline(DropdownComponent.new(
					kind: :menu, name: "right", label: "R", align: :right,
					options: [ { label: "X", url: "/x" } ]
			)).at_css("[data-dropdown-target='menu']")
			assert_includes menu["class"], "right-0"
			refute_includes menu["class"], "left-0"
	end

	test "sub inherits left-start from a flipped parent" do
			menu = render_inline(DropdownComponent.new(
					kind: :menu, name: "s1", sub: true, label: "S",
					parent_place: "bottom-end",
					options: [ { label: "X", url: "/x" } ]
			)).at_css("[data-dropdown-target='menu']")
			assert_includes menu["class"], "right-full"
			assert_includes menu["class"], "mr-1"
	end

	test "sub inherits right-start from a normal parent" do
			menu = render_inline(DropdownComponent.new(
					kind: :menu, name: "s2", sub: true, label: "S",
					parent_place: "bottom-start",
					options: [ { label: "X", url: "/x" } ]
			)).at_css("[data-dropdown-target='menu']")
			assert_includes menu["class"], "left-full"
			assert_includes menu["class"], "ml-1"
	end

	test "recursion propagates parent_place into the nested component" do
			# Outer is flipped; the template passes parent_place to the recursive
			# render. Inner's menu must reflect that.
			fragment = render_inline(DropdownComponent.new(
					kind: :menu, name: "outer", label: "O", align: :right,
					options: [
							{
									name: "inner", kind: :menu, label: "I",
									options: [ { label: "Deep", url: "/deep" } ]
							}
					]
			))
			inner = fragment.at_css("#inner")
			assert_includes inner["class"], "right-full",
					"inner menu must inherit left-start from the flipped outer"
	end

	# ─── flipped link alignment ──────────────────────
	test "leaf links right-align inside a flipped menu" do
			fragment = render_inline(DropdownComponent.new(
					kind: :menu, name: "r", label: "R", align: :right,
					options: [ { label: "One", url: "/one" } ]
			))
			a = fragment.at_css("a")
			assert_includes a["class"], "justify-end",
					"right-aligned menu must right-align leaf text (regression: bracket bug)"
	end

	test "leaf links left-align inside a normal menu" do
			fragment = render_inline(DropdownComponent.new(simple_button))
			a = fragment.at_css("a")
			refute_includes a["class"], "justify-end"
	end

	# ─── chevron rendering ───────────────────────────
	test "flipped sub renders chevron-left before the label" do
			html = render_inline(DropdownComponent.new(
					kind: :menu, name: "s", sub: true, label: "Sub",
					parent_place: "bottom-end",
					options: [ { label: "X", url: "/x" } ]
			)).to_html
			assert_match(/rotate-180.*?<span[^>]*>Sub<\/span>/m, html,
					"chevron-left (rotate-180) must appear before the label span")
	end

	test "normal sub renders chevron-right after the label" do
			html = render_inline(DropdownComponent.new(
					kind: :menu, name: "s", sub: true, label: "Sub",
					parent_place: "bottom-start",
					options: [ { label: "X", url: "/x" } ]
			)).to_html
			assert_match(/<span[^>]*>Sub<\/span>.*?<path fill-rule="evenodd"/m, html,
					"chevron-right must appear after the label span")
	end

	test "flipped sub packs content to the right edge" do
			button = render_inline(DropdownComponent.new(
					kind: :menu, name: "s", sub: true, label: "Sub",
					parent_place: "bottom-end",
					options: [ { label: "X", url: "/x" } ]
			)).at_css("button")
			assert_includes button["class"], "justify-end",
					"flipped sub-trigger must pack chevron + label to the right edge"
	end

	test "label span has no flex-1 (chevron placement regression)" do
			html = render_inline(DropdownComponent.new(
					kind: :menu, name: "s", sub: true, label: "Sub",
					parent_place: "bottom-start",
					options: [ { label: "X", url: "/x" } ]
			)).to_html
			span = Nokogiri::HTML.fragment(html).at_css("button > span")
			refute_includes span["class"], "flex-1",
					"flex-1 on the label pins the chevron to the frame — must not be used"
			assert_includes span["class"], "truncate"
	end

	test "hamburger variant renders no chevron" do
			html = render_inline(DropdownComponent.new(
					kind: :menu, name: "ham", ham: true,
					options: [ { label: "X", url: "/x" } ]
			)).to_html
			refute_match(/rotate-180|M19 9l-7 7-7-7/, html,
					"hamburger has no label → no chevron branch should render")
	end

	# ─── CSS compilation guard ──────────────────────
	test "dropdown classes compile into the Tailwind output" do
			css_path = Rails.root.join("app/assets/builds/tailwind.css")
			assert File.exist?(css_path), "Run `bin/rails tailwindcss:build` first"
			css = File.read(css_path).gsub(/\\/, "")

			# Classes this component actually emits, one per line for easy auditing.
			# If you add a constant to DropdownComponent, add its classes here.
			required = %w[
					inline-flex items-center whitespace-nowrap rounded-md
					hover:bg-green-200 focus:bg-green-200 focus:ring-green-500
					hover:bg-blue-700 focus:ring-gray-200
					hover:bg-gray-300 focus:ring-gray-300 focus:border-gray-300
					bg-gray-200 text-gray-500 bg-blue-900 bg-gray-100
					hidden p-1 font-semibold
					block no-underline
					h-6 w-6 h-4 w-4
					relative inline-block absolute z-10
					top-full left-0 mt-1
					left-full top-0 ml-1
					right-full top-0 mr-1
					top-full right-0 mt-2
					justify-end gap-2 gap-1 truncate shrink-0 rotate-180
					focus:outline-none
			]

			missing = required.reject { |cls| css.include?(cls) }
			assert_empty missing,
					"Missing compiled classes: #{missing.join(', ')}. " \
					"Fix: add `@source \"../../app/components/**/*.rb\";` to " \
					"app/assets/tailwind/application.css (or the equivalent content " \
					"entry in tailwind.config.js), then run `bin/rails tailwindcss:build`."
	end
end

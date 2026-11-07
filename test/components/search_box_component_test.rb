require "test_helper"

class SearchBoxComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# ─── simple single-field mode ──────────────────
	test "renders the wrapper with search-box id and class" do
		html = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/search")
		).to_html
		wrapper = parsed(html).css("#search-box").first

		refute_nil wrapper
		assert_includes wrapper["class"].to_s, "inline-flex"
		assert_includes wrapper["class"].to_s, "rounded-md"
		assert_includes wrapper["class"].to_s, "border-2"
	end

	test "renders the search-form Stimulus controller on the form" do
		html = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/search")
		).to_html
		form = parsed(html).css("form").first

		refute_nil form
		assert_equal "/search", form["action"]
		assert_equal "get", form["method"]
		assert_includes form["data-controller"], "search-form"
		assert_equal "search-results", form["data-turbo-frame"]
	end

	test "renders a text input for :search_text" do
		html = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/search")
		).to_html
		input = parsed(html).css('input[type="text"]').first

		refute_nil input
		assert_equal "q", input["name"]
		assert_equal "input->search-form#search", input["data-action"]
	end

	test "renders the search button with the search symbol" do
		html = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/search")
		).to_html
		button = parsed(html).css('button[type="submit"]').first

		refute_nil button
		assert_match(/common\.button\.search|search/, html)
	end

	# ─── label behavior ────────────────────────────
	test "renders a label when field[:label] is present" do
		html = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/search", label: "Buscar")
		).to_html

		label = parsed(html).css("label").first
		refute_nil label
		assert_equal "Buscar", label.text
	end

	test "does not render a label when field[:label] is absent" do
		html = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/search")
		).to_html
		assert_equal 0, parsed(html).css("label").size
	end

	# ─── multi-field mode ──────────────────────────
	test "renders one input per field for :search_box" do
		html = render_inline(
			SearchBoxComponent.new(
				kind: :search_box,
				url:  "/search",
				fields: [
					{ kind: :search_text, key: :name, label: "Nombre" },
					{ kind: :search_text, key: :nick, label: "Nick" }
				]
			)
		).to_html

		inputs = parsed(html).css('input[type="text"]')
		assert_equal 2, inputs.size
		assert_equal %w[name nick], inputs.map { |i| i["name"] }
	end

	# ─── select fields ─────────────────────────────
	test "renders a select for :search_select" do
		html = render_inline(
			SearchBoxComponent.new(
				kind: :search_select,
				key:  :status,
				url:  "/search",
				options: [ %w[Active active], %w[Inactive inactive] ]
			)
		).to_html

		select = parsed(html).css("select").first
		refute_nil select
		assert_equal "status", select["name"]
		assert_equal 2, select.css("option").size
	end

	test "renders a collection_select for :search_collection" do
		Option   = Struct.new(:id, :name)   # or use your existing Team fixture
		options  = [ Option.new(1, "One"), Option.new(2, "Two") ]

		html = render_inline(
			SearchBoxComponent.new(
				kind:    :search_collection,
				key:     :team_id,
				url:     "/search",
				options: options
			)
		).to_html

		select = parsed(html).css("select").first
		refute_nil select
		assert_equal 2, select.css("option").size
	end

	# ─── hidden filter ─────────────────────────────
	test "renders a hidden filter field when filter is present" do
		html = render_inline(
			SearchBoxComponent.new(
				kind: :search_text, key: :q, url: "/search",
				filter: { key: :club_id, value: 5 }
			)
		).to_html

		hidden = parsed(html).css('input[type="hidden"][name="club_id"]').first
		refute_nil hidden
		assert_equal "5", hidden["value"]
	end

	test "does not render a hidden field when filter is absent" do
		html = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/search")
		).to_html
		assert_equal 0, parsed(html).css('input[type="hidden"]').size
	end

	# ─── CSS presence ──────────────────────────────
	test "all search-box classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			inline-flex rounded-md border-2 border-gray-300
			relative align-middle block px-1 py-0 w-full
			text-gray-900 bg-gray-50 shadow-inner rounded
			border-1 appearance-none focus:outline-none focus:ring-0 focus:border-blue-700
			peer absolute text-base font-semibold text-gray-700
			duration-300 transform -translate-y-4 scale-75 top-2 origin-[0]
			peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2
			peer-placeholder-shown:top-1/2 peer-focus:top-2 peer-focus:scale-75
			peer-focus:-translate-y-4 hover:bg-gray-300
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls}"
		end
	end

	test "no bare 'text-md' class is emitted (invalid Tailwind utility)" do
		html = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/search", label: "X")
		).to_html
		refute_includes html, "text-md"
	end

	# ─── class-string stability (the constant-mutation bug) ───
	test "repeated renders do not accumulate class tokens" do
		first = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/a", label: "L")
		).to_html
		second = render_inline(
			SearchBoxComponent.new(kind: :search_text, key: :q, url: "/b")
		).to_html

		first_input  = parsed(first).css('input[type="text"]').first
		second_input = parsed(second).css('input[type="text"]').first

		# First render (with label) should have mt-3
		assert_includes first_input["class"].to_s, "mt-3"
		# Second render (no label) should NOT have mt-3 -- catches the class leak
		refute_includes second_input["class"].to_s, "mt-3",
			"class constant leaked from previous render"
		# Second render should have align-middle
		assert_includes second_input["class"].to_s, "align-middle"
	end
end

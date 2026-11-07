require "test_helper"

class TrafficLightComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def render_light(status:, size: :medium)
		render_inline(TrafficLightComponent.new(status: status, size: size)).to_html
	end

	def light_dom(status:, size: :medium)
		parsed(render_light(status: status, size: size)).css("div").first
	end

	# ─── status → color mapping ────────────────────────────────────
	test "red status renders red classes" do
		div = light_dom(status: :red)
		assert_includes div["class"], "bg-red-500"
		assert_includes div["class"], "border-red-600"
	end

	test "orange status renders dark-yellow classes" do
		div = light_dom(status: :orange)
		assert_includes div["class"], "bg-yellow-700"
		assert_includes div["class"], "border-yellow-800"
	end

	test "yellow status renders light-yellow classes" do
		div = light_dom(status: :yellow)
		assert_includes div["class"], "bg-yellow-400"
		assert_includes div["class"], "border-yellow-500"
	end

	test "lime status renders light-green classes" do
		div = light_dom(status: :lime)
		assert_includes div["class"], "bg-green-300"
		assert_includes div["class"], "border-green-400"
	end

	test "green status renders saturated green classes" do
		div = light_dom(status: :green)
		assert_includes div["class"], "bg-green-500"
		assert_includes div["class"], "border-green-600"
	end

	test "orange and yellow map to distinct shades" do
		# Both use the yellow palette but at different stops — pin that
		# so a future cleanup doesn't collapse them into one class.
		orange = light_dom(status: :orange)["class"]
		yellow = light_dom(status: :yellow)["class"]

		refute_equal orange, yellow
		assert_includes orange, "bg-yellow-700"
		assert_includes yellow, "bg-yellow-400"
	end

	# ─── fallback ─────────────────────────────────────────────────
	test "unknown status falls back to neutral gray" do
		div = light_dom(status: :bogus)
		assert_includes div["class"], "bg-gray-300"
		assert_includes div["class"], "border-gray-400"
	end

	test "nil status falls back to neutral gray" do
		div = light_dom(status: nil)
		assert_includes div["class"], "bg-gray-300"
		assert_includes div["class"], "border-gray-400"
	end

	test "explicit :default status renders neutral gray" do
		div = light_dom(status: :default)
		assert_includes div["class"], "bg-gray-300"
	end

	test "unknown status and :default render identical markup" do
		# The hash has both a :default key and a `|| ` fallback — they
		# should agree, otherwise behaviour depends on which status a
		# caller happens to pass for "no state".
		unknown = parsed(render_light(status: :bogus)).css("div").first
		default = parsed(render_light(status: :default)).css("div").first

		assert_equal default["class"], unknown["class"]
		assert_equal default["title"], unknown["title"]
	end

	# ─── size mapping ─────────────────────────────────────────────
	test "small size uses w-3 h-3" do
		div = light_dom(status: :green, size: :small)
		assert_includes div["class"], "w-3"
		assert_includes div["class"], "h-3"
	end

	test "medium is the default size (w-4 h-4)" do
		div = light_dom(status: :green)
		assert_includes div["class"], "w-4"
		assert_includes div["class"], "h-4"
	end

	test "large size uses w-6 h-6" do
		div = light_dom(status: :green, size: :large)
		assert_includes div["class"], "w-6"
		assert_includes div["class"], "h-6"
	end

	# ─── structure ────────────────────────────────────────────────
	test "renders a rounded-full, 2px-bordered, inline-block div" do
		div = light_dom(status: :green)
		assert_equal "div", div.name
		assert_includes div["class"], "rounded-full"
		assert_includes div["class"], "border-2"
		assert_includes div["class"], "inline-block"
	end

	test "has no children (it's a pure indicator)" do
		div = light_dom(status: :green)
		assert_equal 0, div.element_children.size
		assert_equal "", div.text.strip
	end

	# ─── title attribute ──────────────────────────────────────────
	test "title maps each named status to its I18n key" do
		{
			red:    "status.not_started",
			orange: "status.starting",
			yellow: "status.in_progress",
			lime:   "status.good",
			green:  "status.completed"
		}.each do |status, key|
			div = light_dom(status: status)
			assert_equal I18n.t(key), div["title"],
				"status :#{status} should map to #{key}"
		end
	end

	test "unknown status uses the inactive title" do
		assert_equal I18n.t("status.inactive"), light_dom(status: :bogus)["title"]
	end

	# ─── CSS presence ─────────────────────────────────────────────
	test "all status, size, and structural classes compile into Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			bg-red-500 border-red-600
			bg-yellow-700 border-yellow-800
			bg-yellow-400 border-yellow-500
			bg-green-300 border-green-400
			bg-green-500 border-green-600
			bg-gray-300 border-gray-400
			rounded-full border-2 inline-block
			w-3 h-3 w-4 h-4 w-6 h-6
		].each do |cls|
			assert_includes css, cls,
				"Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

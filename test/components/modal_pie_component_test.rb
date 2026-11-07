require "test_helper"

class ModalPieComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def header_fields
		[
			[ { kind: :string, value: "Pie Chart Title" } ]
		]
	end

	def chart_data
		{
			title: "Sample Chart",
			data:  { "Apples" => 10, "Oranges" => 20, "Bananas" => 15 }
		}
	end

	def render_pie(header: header_fields, chart: chart_data)
		render_inline(ModalPieComponent.new(header: header, chart: chart)).to_html
	end

	# ─── wrapper structure ──────────────────────────
	test "renders the ModalComponent Turbo frame wrapper" do
		html = render_pie
		assert_match(/<turbo-frame[^>]*id="modal"/, html)
	end

	test "renders the modal backdrop and card" do
		html = render_pie
		assert_includes html, "data-controller=\"turbo-modal\""
		assert_includes html, "bg-white"
		assert_includes html, "rounded-lg"
		assert_includes html, "shadow-xl"
	end

	test "renders the modal-body Turbo frame" do
		html = render_pie
		assert_match(/<turbo-frame[^>]*id="modal-body"/, html)
	end

	# ─── simple mode → close button ─────────────────
	test "renders a close button because simple: true" do
		html = render_pie
		assert_includes html, "close-btn"
		assert_includes html, I18n.t("action.close")
	end

	# ─── header fields ──────────────────────────────
	test "renders the header FieldsComponent inside the modal" do
		html = render_pie
		assert_includes html, "Pie Chart Title"
	end

	test "header renders as a table (FieldsComponent structure)" do
		html = render_pie
		assert_match(/<table\b/, html)
		assert_match(/<td\b/, html)
	end

	# ─── chartkick chart ────────────────────────────
	test "renders a chartkick chart container" do
		html = render_pie
		# Chartkick generates a container with an id like "chart-<hash>"
		assert_match(/id="chart-[^"]+"/, html)
		# And initializes the chart via an inline Chartkick script
		assert_includes html, "Chartkick"
	end

	test "chart container includes the chart title" do
		html = render_pie
		assert_includes html, "Sample Chart"
	end

	test "chart container includes the chart series data" do
		html = render_pie
		# Chartkick embeds data as a JSON attribute on the container
		assert_includes html, "Apples"
		assert_includes html, "Oranges"
		assert_includes html, "Bananas"
	end

	# ─── empty chart guard ──────────────────────────
	test "renders without raising when chart data is empty" do
		html = render_inline(
			ModalPieComponent.new(header: header_fields, chart: {})
		).to_html
		assert_match(/<turbo-frame[^>]*id="modal"/, html)
	end

	# ─── CSS presence ───────────────────────────────
	test "modal classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			fixed inset-0 z-20 z-30 flex justify-center items-start
			bg-white rounded-lg shadow-xl flex-col p-3
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls}"
		end
	end

	test "modal backdrop uses v4-compatible opacity syntax" do
		html = render_pie
		refute_includes html, "bg-opacity-75"
		assert html.include?("bg-gray-500/75") || html.include?("bg-[rgba("),
			"backdrop should use v4 opacity syntax (/75 or rgba arbitrary value)"
	end
end

require "test_helper"

class ModalComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def render_modal(simple: nil, height: "90%", width: "90%", &block)
		render_inline(
			ModalComponent.new(simple: simple, height: height, width: width)
		) { block ? block.call : "Content" }.to_html
	end

	# ─── structure ──────────────────────────────────
	test "renders the modal Turbo frame wrapper" do
		html = render_modal
		assert_match(/<turbo-frame[^>]*id="modal"/, html)
	end

	test "renders the modal backdrop with the overlay classes" do
		html   = render_modal
		div    = parsed(html).css("div[data-controller='turbo-modal']").first

		refute_nil div
		%w[fixed inset-0 z-20 flex justify-center].each do |cls|
			assert_includes div["class"].to_s, cls
		end
	end

	test "renders an inner content area with the white card" do
		html = render_modal
		assert_includes html, "bg-white"
		assert_includes html, "rounded-lg"
		assert_includes html, "shadow-xl"
	end

	test "renders the modal-body Turbo frame" do
		html = render_modal
		assert_match(/<turbo-frame[^>]*id="modal-body"/, html)
	end

	# ─── content ────────────────────────────────────
	test "renders block content inside the modal-body frame" do
		html = render_modal { "<p>Inner content</p>" }
		assert_includes html, "Inner content"
	end

	# ─── close button ───────────────────────────────
	test "renders no close button by default" do
		html = render_modal
		refute_includes html, 'class="close-btn'
	end

	test "renders a close button when simple: true" do
		html = render_modal(simple: true)
		assert_includes html, 'class="close-btn'
		assert_includes html, I18n.t("action.close")
	end

	# ─── sizing ─────────────────────────────────────
	test "applies the default width and height to the card" do
		html = render_modal
		assert_includes html, "width: 90%"
		assert_includes html, "height: 90%"
	end

	test "applies the requested width and height" do
		html = render_modal(width: "50%", height: "40%")
		assert_includes html, "width: 50%"
		assert_includes html, "height: 40%"
	end

	test "no empty width/height style is emitted" do
		html = render_modal
		refute_match(/width:\s*;/, html)
		refute_match(/height:\s*;/, html)
	end

	# ─── Stimulus wiring ────────────────────────────
	test "wraps the outer container in the turbo-modal controller" do
		html = render_modal
		assert_includes html, 'data-controller="turbo-modal"'
		assert_includes html, 'data-turbo-modal-target="modal"'
	end

	# ─── CSS presence ───────────────────────────────
	test "backdrop classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			fixed inset-0 z-20 z-30 flex justify-center items-start
			top-10 bottom-0 m-2 overflow-auto
			bg-white rounded-lg shadow-xl flex-col p-3 mt-3 ml-3
			flow-root float-left
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end

	test "backdrop uses v4-compatible opacity syntax" do
		html = render_modal
		# Either bg-gray-500/75 (color-mix) or bg-[rgba(...)] (plain rgba)
		# are acceptable. bg-opacity-75 is not.
		refute_includes html, "bg-opacity-75"
		assert html.include?("bg-gray-500/75") || html.include?("bg-[rgba("),
			"backdrop should use v4 opacity syntax (/75 or rgba arbitrary value)"
	end
end

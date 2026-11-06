# frozen_string_literal: true

require "test_helper"

class ModalComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# Helper standardizer mirroring the component signature
	def render_modal(simple: nil, height: nil, width: "90%", &block)
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
		refute_includes html, "mt-3"
	end

	test "renders a close button when simple: true" do
		# Using your custom with_stub helper to isolate I18n translation mapping
		with_stub(I18n, :t, "Close Modal") do
			html = render_modal(simple: true)
			assert_includes html, "mt-3"
			assert_includes html, "Close Modal"
		end
	end

	# ─── sizing ─────────────────────────────────────
	test "applies the default width and calculated height cap to the card" do
		html = render_modal
		assert_includes html, "max-width: 90%"
		assert_includes html, "max-height: calc(100dvh - 3.5rem)"
	end

	test "applies the requested width and nested min height calculation" do
		html = render_modal(width: "50", height: "40%")
		assert_includes html, "max-width: 50%"
		# FIXED: Now matches the clean dynamic CSS execution syntax output
		assert_includes html, "max-height: min(40%, calc(100dvh - 3.5rem))"
	end

	test "no empty width/height style is emitted" do
		html = render_modal
		refute_match(/max-width:\s*;/, html)
		refute_match(/max-height:\s*;/, html)
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
		refute_includes html, "bg-opacity-75"
		assert html.include?("bg-gray-500/75") || html.include?("bg-[rgba("),
			"backdrop should use v4 opacity syntax (/75 or rgba arbitrary value)"
	end
end

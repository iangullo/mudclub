require "test_helper"

class DiagramComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def form_builder(model = Drill.new)
		controller = ApplicationController.new
		controller.request = ActionDispatch::TestRequest.create
		ActionView::Helpers::FormBuilder.new(model.model_name.param_key, model, controller.view_context, {})
	end

	# ─── display mode (no form) ─────────────────────
	test "display mode renders a diagram-renderer container" do
		html = render_inline(DiagramComponent.new(court: "full", svgdata: {})).to_html
		assert_includes html, 'data-controller="diagram-renderer"'
	end

	test "display mode does not render editor buttons" do
		html = render_inline(DiagramComponent.new(court: "full", svgdata: {})).to_html
		refute_includes html, "diagram-editor-buttons"
		refute_includes html, "diagram_editor_target"
	end

	test "display mode does not render the color menu" do
		html = render_inline(DiagramComponent.new(court: "full", svgdata: {})).to_html
		refute_includes html, 'id="color-menu"'
	end

	test "display mode does not render a svgdata hidden field" do
		html = render_inline(DiagramComponent.new(court: "full", svgdata: {})).to_html
		refute_includes html, 'name="drill[svgdata]"'
	end

	test "display mode uses SHOW_SVG_CLASS by default" do
		html = render_inline(DiagramComponent.new(court: "full", svgdata: {})).to_html
		assert_includes html, "w-full"
		assert_includes html, "h-auto"
	end

	test "display mode honors an explicit css option" do
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, css: "custom-diagram")
		).to_html
		assert_includes html, "custom-diagram"
	end

	# ─── editor mode (form present) ─────────────────
	test "editor mode renders the editor buttons container" do
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, form: form_builder)
		).to_html
		assert_includes html, 'id="diagram-editor-buttons"'
	end

	test "editor mode renders one button per EDITOR_BUTTONS entry" do
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, form: form_builder)
		).to_html
		assert_equal DiagramComponent::EDITOR_BUTTONS.size,
								html.scan(/data-diagram-editor-target="\w+Button"/).size
	end

	test "editor mode renders the color menu" do
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, form: form_builder)
		).to_html
		assert_includes html, 'id="color-menu"'
		assert_includes html, 'data-diagram-editor-target="colorMenu"'
	end

	test "editor mode renders the svgdata hidden field" do
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, form: form_builder)
		).to_html
		assert_includes html, 'name="drill[svgdata]"'
		assert_includes html, 'data-diagram-editor-target="svgdata"'
	end

	test "editor mode does not render step_id or order hidden fields" do
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, form: form_builder)
		).to_html
		refute_includes html, 'name="drill[step_id]"'
		refute_includes html, 'name="drill[order]"'
	end

	test "editor mode uses EDIT_SVG_CLASS" do
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, form: form_builder)
		).to_html
		assert_includes html, "w-full"
		assert_includes html, "h-full"
	end

	# ─── symbol definitions ─────────────────────────
	test "editor mode renders a defs block for the add-object symbols" do
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, form: form_builder)
		).to_html
		assert_includes html, "<defs"
		assert_includes html, "<symbol"
	end

	test "editor mode renders exactly five symbol definitions" do
		# Only the "add" actions contribute symbols: attacker, defender, ball, cone, coach
		html = render_inline(
			DiagramComponent.new(court: "full", svgdata: {}, form: form_builder)
		).to_html
		assert_equal 5, html.scan(/<symbol\b/).size
	end

	# ─── ID uniqueness ──────────────────────────────
	test "each diagram gets a unique DOM id" do
		html1 = render_inline(DiagramComponent.new(court: "full", svgdata: {})).to_html
		html2 = render_inline(DiagramComponent.new(court: "full", svgdata: {})).to_html

		id1 = html1[/id="(diagram-[a-f0-9]+)"/, 1]
		id2 = html2[/id="(diagram-[a-f0-9]+)"/, 1]

		refute_nil id1
		refute_nil id2
		refute_equal id1, id2
	end

	test "diagram id matches the SecureRandom hex(4) pattern" do
		html = render_inline(DiagramComponent.new(court: "full", svgdata: {})).to_html
		assert_match(/id="diagram-[a-f0-9]{8}"/, html)
	end

	# ─── CSS presence (locks the migration fixes) ──
	test "diagram classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			hover:bg-red-100 hover:bg-gray-100
			w-full h-auto w-full h-full
			m-1 rounded
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

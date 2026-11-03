require "test_helper"

class PdfComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def render_pdf(file: "/sample.pdf", **opts)
		render_inline(PdfComponent.new(file: file, **opts)).to_html
	end

	def iframe_of(html)
		parsed(html).css("iframe").first
	end

	# ─── wrapper ────────────────────────────────────
	test "renders a wrapper div with w-full by default" do
		wrapper = parsed(render_pdf).css("div").first

		refute_nil wrapper
		assert_includes wrapper["class"].to_s, "w-full"
	end

	test "honors a custom css on the wrapper" do
		html = render_pdf(css: "custom-pdf-wrapper")
		assert_includes html, "custom-pdf-wrapper"
	end

	# ─── iframe ─────────────────────────────────────
	test "renders an iframe with the given src" do
		iframe = iframe_of(render_pdf)
		refute_nil iframe
		assert_equal "/sample.pdf", iframe["src"]
	end

	test "iframe carries loading=lazy" do
		iframe = iframe_of(render_pdf)
		assert_equal "lazy", iframe["loading"]
	end

	test "iframe has border and rounded classes" do
		iframe = iframe_of(render_pdf)
		assert_includes iframe["class"].to_s, "border"
		assert_includes iframe["class"].to_s, "rounded"
	end

	# ─── sizing defaults ────────────────────────────
	test "defaults to h-full w-full when no size is given" do
		iframe = iframe_of(render_pdf)
		assert_includes iframe["class"].to_s, "h-full"
		assert_includes iframe["class"].to_s, "w-full"
	end

	test "does not emit a style attribute when no size is given" do
		iframe = iframe_of(render_pdf)
		assert_nil iframe["style"]
	end

	# ─── sizing overrides ───────────────────────────
	test "applies custom height and width to the iframe style" do
		iframe = iframe_of(render_pdf(height: "500px", width: "800px"))

		assert_includes iframe["style"].to_s, "height: 500px"
		assert_includes iframe["style"].to_s, "width: 800px"
	end

	test "custom height/width are NOT added as class names" do
		iframe = iframe_of(render_pdf(height: "500px", width: "800px"))

		refute_includes iframe["class"].to_s, "500px"
		refute_includes iframe["class"].to_s, "800px"
		refute_includes iframe["class"].to_s, "h-full"
		refute_includes iframe["class"].to_s, "w-full"
	end

	test "height only leaves width at w-full" do
		iframe = iframe_of(render_pdf(height: "500px"))

		assert_includes iframe["class"].to_s, "w-full"
		refute_includes iframe["class"].to_s, "h-full"
		assert_includes iframe["style"].to_s, "height: 500px"
		refute_includes iframe["style"].to_s, "width:"
	end

	# ─── nil file guard (if render? added) ──────────
	test "renders nothing when file is nil" do
		html = render_inline(PdfComponent.new(file: nil)).to_html
		assert_equal "", html.strip
	end

	# ─── CSS presence ───────────────────────────────
	test "iframe classes compile in the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[border rounded h-full w-full].each do |cls|
			assert_includes css, cls
		end
	end
end

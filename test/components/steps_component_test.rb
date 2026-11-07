require "test_helper"

class StepsComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# ─── test doubles ──────────────────────────────────────────────
	# Step is an AR model with ActionText + ActiveStorage + sport
	# delegation. For a component test we only need the interface
	# StepsComponent actually calls, so plain objects are cleaner.
	# Full end-to-end coverage belongs in an integration test.

	FakeExplanation = Struct.new(:body)
	FakeSport       = Struct.new(:name)
	FakeDiagram     = Struct.new(:attachment)

	FakeStep = Struct.new(:order, :kind, keyword_init: true) do
		def has_text?;  %i[text text_svg text_image].include?(kind); end
		def has_svg?;   %i[svg text_svg].include?(kind); end
		def has_image?; %i[image text_image].include?(kind); end

		def explanation
			return nil unless has_text?
			FakeExplanation.new("Explanation for step #{order}")
		end

		def svgdata
			has_svg? ? { stub: true } : nil
		end

		def diagram
			return nil unless has_image?
			FakeDiagram.new("stub-attachment")
		end

		def sport
			FakeSport.new("Basketball")
		end
	end

	# StepsComponent#initialize calls steps.order(:order). Give a plain
	# Array a no-op `.order` so we don't need a real AR relation.
	def steps_relation(*steps)
		steps.tap { |arr| arr.define_singleton_method(:order) { |_| self } }
	end

	def build_component(steps:, court: nil, klass: StepsComponent)
		klass.new(steps: steps_relation(*steps), court: court)
	end

	def fake_diagram_component(html: "<svg class='stub-svg'></svg>")
		fake = Object.new
		fake.define_singleton_method(:render_in) { |_vc| html.html_safe }
		fake
	end

	# ─── header ────────────────────────────────────────────────────
	test "renders singular header for a single step" do
		html = render_inline(build_component(steps: [ FakeStep.new(order: 1, kind: :text) ])).to_html
		assert_includes html, I18n.t("step.explanation")
		refute_includes html, I18n.t("step.many")
	end

	test "renders plural header when more than one step" do
		steps = [ FakeStep.new(order: 1, kind: :text), FakeStep.new(order: 2, kind: :text) ]
		html  = render_inline(build_component(steps: steps)).to_html
		assert_includes html, I18n.t("step.many")
	end

	# ─── structure ─────────────────────────────────────────────────
	test "wraps content in responsive-steps container with responsive spacing" do
		html = render_inline(build_component(steps: [ FakeStep.new(order: 1, kind: :text) ])).to_html
		wrapper = parsed(html).css(".responsive-steps").first

		refute_nil wrapper
		assert_includes wrapper["class"], "space-y-2"
		assert_includes wrapper["class"], "md:space-y-4"
	end

	test "renders one step-container per step" do
		steps = 3.times.map { |i| FakeStep.new(order: i + 1, kind: :text) }
		html  = render_inline(build_component(steps: steps)).to_html
		assert_equal 3, parsed(html).css(".step-container").size
	end

	# ─── order number ──────────────────────────────────────────────
	test "order number is rendered when there are multiple steps" do
		steps = [ FakeStep.new(order: 1, kind: :text), FakeStep.new(order: 2, kind: :text) ]
		html  = render_inline(build_component(steps: steps)).to_html

		order_tags = parsed(html).css(".step-order")
		assert_equal 2, order_tags.size
		assert_equal [ "1", "2" ], order_tags.map { |t| t.text.strip }
	end

	test "order number is omitted for a single step" do
		html = render_inline(build_component(steps: [ FakeStep.new(order: 1, kind: :text) ])).to_html
		assert_equal 0, parsed(html).css(".step-order").size
	end

	# ─── diagram branch ────────────────────────────────────────────
	test "text-only step renders no diagram wrapper at all" do
		html = render_inline(build_component(steps: [ FakeStep.new(order: 1, kind: :text) ])).to_html
		assert_equal 0, parsed(html).css(".step-diagram").size
	end

	test "svg-only step renders through DiagramComponent at full width" do
		html = nil
		with_stub(DiagramComponent, :new, fake_diagram_component) do
			html = render_inline(build_component(steps: [ FakeStep.new(order: 1, kind: :svg) ])).to_html
		end

		diagram = parsed(html).css(".step-diagram").first
		refute_nil diagram
		assert_includes diagram["class"], "md:w-full"
		assert_includes html, "stub-svg"
	end

	test "text+svg step renders diagram at half width" do
		html = nil
		with_stub(DiagramComponent, :new, fake_diagram_component) do
			html = render_inline(build_component(steps: [ FakeStep.new(order: 1, kind: :text_svg) ])).to_html
		end

		diagram = parsed(html).css(".step-diagram").first
		assert_includes diagram["class"], "md:w-1/2"
	end

	# ─── image branch ──────────────────────────────────────────────
	test "image step is routed through render_image" do
		component = build_component(steps: [ FakeStep.new(order: 1, kind: :image) ])

		with_stub(component, :render_image, '<img class="stub-image" />'.html_safe) do
			html = render_inline(component).to_html

			assert_includes html, "stub-image"
			assert_equal 1, parsed(html).css(".step-diagram").size
		end
	end

	# ─── explanation and split alignment ───────────────────────────
	test "text step renders the explanation body" do
		html = render_inline(build_component(steps: [ FakeStep.new(order: 1, kind: :text) ])).to_html

		explanation = parsed(html).css(".step-explanation").first
		refute_nil explanation
		assert_includes explanation.text, "Explanation for step 1"
	end

	test "svg-only step gets no explanation wrapper when no sibling has text" do
		html = nil
		with_stub(DiagramComponent, :new, fake_diagram_component) do
			html = render_inline(build_component(steps: [ FakeStep.new(order: 1, kind: :svg) ])).to_html
		end

		assert_equal 0, parsed(html).css(".step-explanation").size
	end

	test "svg-only step gets an empty explanation box when a sibling has text" do
		steps = [
			FakeStep.new(order: 1, kind: :text),
			FakeStep.new(order: 2, kind: :svg)
		]

		html = nil
		with_stub(DiagramComponent, :new, fake_diagram_component) do
			html = render_inline(build_component(steps: steps)).to_html
		end

		explanations = parsed(html).css(".step-explanation")
		assert_equal 2, explanations.size
		assert_equal "", explanations[1].text.strip
	end

	# ─── edge case ─────────────────────────────────────────────────
	test "renders header but no step containers when steps are empty" do
		html = render_inline(build_component(steps: [])).to_html

		assert_includes html, "responsive-steps"
		assert_equal 0, parsed(html).css(".step-container").size
		# @many = false (0 > 1) → singular header
		assert_includes html, I18n.t("step.explanation")
	end

	# ─── CSS presence ──────────────────────────────────────────────
	test "structural classes compile into Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			responsive-steps space-y-2 md:space-y-4
			step-container py-2 md:py-3
			step-content flex flex-col md:flex-row gap-3 md:gap-4
			step-diagram justify-center w-full overflow-x-auto
			step-explanation md:min-w-\[50%\]
			step-order inline-flex font-semibold
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end

	test "diagram width classes compile into Tailwind output" do
		# These are interpolated in the component ("md:w-#{width}"),
		# so Tailwind's scanner misses them. Fix by putting literal
		# strings in the source (see review notes) — this test will
		# fail until then.
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[md:w-1/2 md:w-full].each do |cls|
			assert_includes css, cls,
				"Missing compiled class: #{cls} — interpolated in component, " \
				"so Tailwind v4 never sees it. Add a literal string or @source inline(...)"
		end
	end
end

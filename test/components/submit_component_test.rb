require "test_helper"

class SubmitComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def render_component(**kwargs)
		render_inline(SubmitComponent.new(**kwargs)).to_html
	end

	# ─── wrapper layout ────────────────────────────────────────────
	test "wrapper uses flex, not float, for horizontal layout" do
		html = render_component
		wrapper = parsed(html).element_children.first

		assert_includes wrapper["class"], "flex"
		refute_includes wrapper["class"], "inline-flex",
			"inline-flex conflicts with flow-root and disables float-right"
		refute_includes wrapper["class"], "flow-root",
			"flow-root is redundant once flex layout is used"
	end

	test "wrapper uses justify-between to push actions right" do
		html = render_component(submit: :save)
		wrapper = parsed(html).element_children.first
		assert_includes wrapper["class"], "justify-between"
	end

	test "wrapper uses items-center for vertical alignment" do
		html = render_component(submit: :save)
		wrapper = parsed(html).element_children.first
		assert_includes wrapper["class"], "items-center"
		refute_includes wrapper["class"], "align-middle"
	end

	test "wrapper spans available width so justify-between has room to work" do
		wrapper = parsed(render_component(submit: :save)).element_children.first
		assert_includes wrapper["class"], "w-full"
	end

	# ─── close button placement ───────────────────────────────────
	test "close button is rendered in the left column" do
		html   = render_component(close: :close, retlnk: "/back")
		wrapper = parsed(html).element_children.first
		left   = wrapper.element_children.first

		refute_nil left
		assert_equal "div", left.name
		assert_match %r{cancel|close|/back}, left.to_html
		refute_includes left["class"].to_s, "float-left",
			"flex layout should not use float-left"
	end

	test "left column is an empty placeholder when there is no close button" do
		# Without a placeholder, justify-between pushes actions to the left
		html = render_component(close: false, submit: :save)
		wrapper = parsed(html).element_children.first
		left = wrapper.element_children.first

		refute_nil left
		assert_equal "", left.text.strip
		assert_equal 0, left.css("a, button").size
	end

	test "empty component with close: false renders no interactive elements" do
		html = render_component(close: false)
		wrapper = parsed(html).element_children.first
		assert_equal 0, wrapper.css("a, button").size
	end

	# ─── submit button ────────────────────────────────────────────
	test "submit :save renders a button" do
		html = render_component(submit: :save)
		assert parsed(html).css("button, input[type='submit']").any?
	end

	test "submit with URL renders a link" do
		html = render_component(submit: "/somewhere")
		assert parsed(html).css("a[href='/somewhere']").any?
	end

	test "submit accepts an options hash" do
		html = render_component(submit: { kind: :save, label: "Confirm" })
		assert_includes html, "Confirm"
	end

	# ─── actions list ─────────────────────────────────────────────
	test "renders a single action" do
		html = render_component(actions: [ { kind: :edit, url: "/edit" } ])
		assert_equal 1, parsed(html).css("a[href='/edit']").size
	end

	test "renders multiple actions in order" do
		html = render_component(close: false, actions: [
			{ kind: :edit,   url: "/edit"   },
			{ kind: :remove, url: "/remove" }
		])

		hrefs = parsed(html).css("a[href]").map { |a| a["href"] }
		assert_equal [ "/edit", "/remove" ], hrefs
	end

	test "actions render before the submit button" do
		html = render_component(
			submit:  :save,
			close:   false,                                # isolate the right block
			actions: [ { kind: :edit, url: "/edit" } ]
		)

		right_block = parsed(html).css(".ml-4.mr-1").first
		refute_nil right_block, "could not find the right-hand actions block"

		interactives = right_block.css("a, button")
		assert_operator interactives.size, :>=, 2,
			"expected at least edit + submit in right block, got #{interactives.map(&:name)}"

		edit_pos = interactives.index { |el| el["href"] == "/edit" }
		refute_nil edit_pos, "no /edit link inside the right-hand block"

		assert edit_pos < (interactives.size - 1),
			"actions should appear before the submit button (edit at #{edit_pos}, " \
			"submit expected at #{interactives.size - 1})"
	end

	test "actions list is empty when actions: is nil" do
		html = render_component(submit: :save, close: false)
		# Only submit renders, no action buttons
		buttons = parsed(html).css("a, button")
		assert_equal 1, buttons.size
	end

	# ─── close labels ─────────────────────────────────────────────
	test "close label is 'cancel' when kind: :close and submit: :save" do
		html = render_component(close: :close, submit: :save)
		assert_includes html, I18n.t("action.cancel")
	end

	test "close label is 'close' when kind: :close and no save" do
		html = render_component(close: :close)
		assert_includes html, I18n.t("action.close")
	end

	# ─── frame handling ───────────────────────────────────────────
	test "cancel passes frame through, close does not" do
		html = render_component(close: :cancel, frame: "some-frame")
		assert_match(/turbo-frame[^>]*some-frame|data-turbo-frame[^>]*some-frame/, html)
	end

	test "close does not pass frame" do
		html = render_component(close: :close, frame: "some-frame", retlnk: "/back")
		refute_match(/data-turbo-frame[^>]*some-frame/, html)
	end

	# ─── empty component ──────────────────────────────────────────
	test "empty component renders just the wrapper" do
		html = render_component(close: false, submit: nil, actions: [])
		wrapper = parsed(html).element_children.first

		refute_nil wrapper
		assert_equal 0, wrapper.css("a, button").size
	end

	# ─── CSS presence ─────────────────────────────────────────────
	test "layout classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			flex items-center justify-between
			mt-2 mb-1 ml-2 mr-4 mr-1 ml-4
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

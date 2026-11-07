require "test_helper"

class FlashComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# ─── rendering / message extraction ─────────────
	test "renders nothing for nil" do
		html = render_inline(FlashComponent.new(nil)).to_html
		assert_equal "", html.strip
	end

	test "renders nothing for a blank string" do
		html = render_inline(FlashComponent.new("")).to_html
		assert_equal "", html.strip
	end

	test "renders a string notice as info" do
		html = render_inline(FlashComponent.new("Hello")).to_html
		assert_includes html, "Hello"
		assert_includes html, 'role="alert"'
		assert_includes html, "bg-gray-100"
	end

	test "renders a hash notice with symbol keys" do
		html = render_inline(FlashComponent.new({ message: "Saved", kind: :success })).to_html
		assert_includes html, "Saved"
		assert_includes html, "bg-indigo-100"
	end

	test "renders a hash notice with string keys" do
		html = render_inline(FlashComponent.new({ "message" => "Saved", "kind" => "success" })).to_html
		assert_includes html, "Saved"
		assert_includes html, "bg-indigo-100"
	end

	test "renders an ActionController::Parameters notice" do
		params = ActionController::Parameters.new(message: "Saved", kind: "success")
		html   = render_inline(FlashComponent.new(params)).to_html
		assert_includes html, "Saved"
		assert_includes html, "bg-indigo-100"
	end

	test "renders a hash notice with no kind as info" do
		html = render_inline(FlashComponent.new({ message: "FYI" })).to_html
		assert_includes html, "FYI"
		assert_includes html, "bg-gray-100"
	end

	# ─── kind-based styling ─────────────────────────
	test "error flashes use red styling" do
		html = render_inline(FlashComponent.new({ message: "Bad", kind: :error })).to_html
		assert_includes html, "bg-red-100"
		assert_includes html, "text-red-900"
		assert_includes html, "hover:bg-red-200"
		assert_includes html, "focus:ring-red-400"
	end

	test "success flashes use indigo styling" do
		html = render_inline(FlashComponent.new({ message: "OK", kind: :success })).to_html
		assert_includes html, "bg-indigo-100"
		assert_includes html, "text-indigo-900"
		assert_includes html, "hover:bg-indigo-200"
		assert_includes html, "focus:ring-indigo-400"
	end

	test "info flashes use gray styling" do
		html = render_inline(FlashComponent.new({ message: "FYI", kind: :info })).to_html
		assert_includes html, "bg-gray-100"
		assert_includes html, "text-gray-900"
		assert_includes html, "hover:bg-gray-200"
		assert_includes html, "focus:ring-gray-400"
	end

	test "unknown kind falls back to info styling" do
		html = render_inline(FlashComponent.new({ message: "X", kind: :bogus })).to_html
		assert_includes html, "bg-gray-100"
		refute_includes html, "bg-red-100"
		refute_includes html, "bg-indigo-100"
	end

	# ─── Stimulus dismissal wiring ──────────────────
	test "the dismiss controller is attached to the wrapper" do
		html = render_inline(FlashComponent.new("X")).to_html
		assert_includes html, 'data-controller="dismiss"'
	end

	test "the close button wires the dismiss action" do
		html = render_inline(FlashComponent.new("X")).to_html
		assert_includes html, 'data-action="click-'
		assert_includes html, 'dismiss#dismiss"'
	end

	test "the close button is labelled for assistive tech" do
		html = render_inline(FlashComponent.new("X")).to_html
		assert_includes html, 'aria-label="Close"'
		assert_includes html, 'type="button"'
	end

	test "the dismiss controller wraps the alert so removal takes the whole unit" do
		fragment = render_inline(FlashComponent.new("X"))

		controller_el = fragment.at_css("[data-controller='dismiss']")
		refute_nil controller_el, "wrapper must carry the dismiss controller"

		assert_not_nil controller_el.at_css("[role='alert']"),
			"the alert must live inside the controller element"
		assert_not_nil controller_el.at_css("[data-action='click->dismiss#dismiss']"),
			"the close button must live inside the controller element"
	end

	# ─── Flowbite has been removed ──────────────────
	test "no Flowbite dismissal attributes are emitted" do
		html = render_inline(FlashComponent.new("X")).to_html
		refute_includes html, "data-dismiss-target"
		refute_includes html, "data-dismiss-duration"
	end

	test "no synthetic alert id is generated" do
		html = render_inline(FlashComponent.new("X")).to_html
		refute_match(/id="alert-/, html)
	end

	test "two flashes do not collide in the DOM" do
		html = [
			render_inline(FlashComponent.new("One")).to_html,
			render_inline(FlashComponent.new("Two")).to_html
		].join

		# No id generation, so the only safety net is the absence of ids,
		# which means duplicates are structurally impossible.
		refute_includes html, 'id="alert-'
		assert_equal 2, html.scan('role="alert"').size
	end

	# ─── CSS presence — locks the migration fix ─────
	test "all flash styling classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			bg-red-100 text-red-900 hover:bg-red-200 focus:ring-red-400
			bg-indigo-100 text-indigo-900 hover:bg-indigo-200 focus:ring-indigo-400
			bg-gray-100 text-gray-900 hover:bg-gray-200 focus:ring-gray-400
			focus:ring-2
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

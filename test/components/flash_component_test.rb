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

	# ─── unique ids ─────────────────────────────────
	test "each flash gets a unique alert id" do
		html1 = render_inline(FlashComponent.new("One")).to_html
		html2 = render_inline(FlashComponent.new("Two")).to_html

		id1 = html1[/id="(alert-[a-f0-9]+)"/, 1]
		id2 = html2[/id="(alert-[a-f0-9]+)"/, 1]

		refute_nil id1
		refute_nil id2
		refute_equal id1, id2, "two flashes must not share an alert id"
	end

	test "alert id follows the alert-xxxx format" do
		html = render_inline(FlashComponent.new("X")).to_html
		assert_match(/id="alert-[a-f0-9]{8}"/, html)
	end

	# ─── Flowbite dismissal wiring ──────────────────
	test "close button targets the flash's own alert id" do
		html = render_inline(FlashComponent.new("X")).to_html

		alert_id   = html[/id="(alert-[a-f0-9]+)"/, 1]
		dismiss_id = html[/data-dismiss-target="#(alert-[a-f0-9]+)"/, 1]

		refute_nil alert_id
		refute_nil dismiss_id
		assert_equal alert_id, dismiss_id,
			"dismiss target must match the element's own id"
	end

	test "wrapper carries Flowbite's dismiss duration attribute" do
		html = render_inline(FlashComponent.new("X")).to_html
		assert_includes html, 'data-dismiss-duration="300"'
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

require "test_helper"

class ButtonComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# ─── validation ─────────────────────────────────
	test "raises when :kind is missing" do
		assert_raises(ArgumentError) { ButtonComponent.new(label: "X") }
	end

	test "raises when :url is missing for a URL-kind" do
		assert_raises(ArgumentError) { ButtonComponent.new(kind: :link) }
	end

	# ─── rendering ──────────────────────────────────
	test "renders a link when :url is given" do
		html = render_inline(ButtonComponent.new(kind: :link, label: "Click", url: "/path")).to_html
		assert_includes html, 'href="/path"'
	end

	test "renders a <button> when :url is not given" do
		html = render_inline(ButtonComponent.new(kind: :action, label: "Go")).to_html
		assert_includes html, "<button"
	end

	test "renders a submit button for :save" do
		html = render_inline(ButtonComponent.new(kind: :save)).to_html
		assert_includes html, 'type="submit"'
	end

	test "renders nothing when initialized with empty hash" do
		# validate raises before this, so this tests the guard directly
		assert_raises(ArgumentError) { ButtonComponent.new({}) }
	end

	# ─── class generation (the CSS bug area) ────────
	test "applies red hover classes for :delete" do
		html = render_inline(ButtonComponent.new(kind: :delete, url: "/x", name: "item"))
		assert_includes html.to_html, "hover:bg-red-200"
		assert_includes html.to_html, "text-red-700"
	end

	test "applies yellow classes for :edit" do
		html = render_inline(ButtonComponent.new(kind: :edit, url: "/x"))
		assert_includes html.to_html, "hover:bg-yellow-200"
		assert_includes html.to_html, "text-yellow-700"
	end

	test "applies green classes for :save" do
		html = render_inline(ButtonComponent.new(kind: :save))
		assert_includes html.to_html, "hover:bg-green-200"
		assert_includes html.to_html, "text-green-700"
	end

	test "applies blue-hover classes for :jump" do
		html = render_inline(ButtonComponent.new(kind: :jump, url: "/x", label: "Go"))
		assert_includes html.to_html, "hover:bg-blue-100"
	end

	test "applies gray classes for :back" do
		html = render_inline(ButtonComponent.new(kind: :back, url: "/x"))
		assert_includes html.to_html, "hover:bg-gray-200"
		assert_includes html.to_html, "text-gray-700"
	end

	test "applies filled blue classes for :login" do
		html = render_inline(ButtonComponent.new(kind: :login))
		assert_includes html.to_html, "bg-blue-900"
		assert_includes html.to_html, "text-gray-200"
		assert_includes html.to_html, "hover:bg-blue-700"
		assert_includes html.to_html, "focus:bg-blue-700"
	end

	test "applies filled gray classes for :action" do
		html = render_inline(ButtonComponent.new(kind: :action))
		assert_includes html.to_html, "bg-gray-100"
		assert_includes html.to_html, "text-gray-700"
		assert_includes html.to_html, "hover:bg-gray-300"
	end

	# ─── URL generation per kind ────────────────────

	test ":call builds a tel: URL from :value" do
		html = render_inline(ButtonComponent.new(kind: :call, value: "666777888")).to_html
		assert_includes html, 'href="tel:666777888"'
	end

	test ":email builds a mailto: URL from :value" do
		html = render_inline(ButtonComponent.new(kind: :email, value: "a@b.c")).to_html
		assert_includes html, 'href="mailto:a@b.c"'
	end

	test ":whatsapp uses the app URL by default" do
		html = render_inline(ButtonComponent.new(kind: :whatsapp, value: "666 77 88 88"))
		assert_includes html.to_html, "whatsapp://send?phone=666778888"
	end

	test ":whatsapp uses the web URL when web: true" do
		html = render_inline(ButtonComponent.new(kind: :whatsapp, value: "666 77 88 88", web: true))
		assert_includes html.to_html, "https://web.whatsapp.com/send?phone=666778888"
	end

	# ─── data attributes ────────────────────────────
	test "turbo_frame defaults to _top" do
		html = render_inline(ButtonComponent.new(kind: :action))
		assert_includes html.to_html, 'turbo-frame="_top"'
	end

	test "turbo_frame can be overridden" do
		html = render_inline(ButtonComponent.new(kind: :action, frame: :modal))
		assert_includes html.to_html, 'turbo-frame="modal"'
	end

	test ":delete sets turbo_method to delete" do
		html = render_inline(ButtonComponent.new(kind: :delete, url: "/x", name: "item"))
		assert_includes html.to_html, 'turbo-method="delete"'
	end

	test "submit kinds set processing controller" do
		html = render_inline(ButtonComponent.new(kind: :save))
		assert_includes html.to_html, 'controller="processing"'
	end

	# ─── labels ─────────────────────────────────────
	test "fills label from I18n for known kinds" do
		html = render_inline(ButtonComponent.new(kind: :back, url: "/x"))
		assert_includes html.to_html, I18n.t("action.back")
	end

	test "custom label is preserved" do
		html = render_inline(ButtonComponent.new(kind: :back, url: "/x", label: "Go back"))
		assert_includes html.to_html, "Go back"
	end

	# ─── custom class overrides ─────────────────────
	test "accepts a custom b_class and preserves it" do
		html = render_inline(ButtonComponent.new(kind: :action, b_class: "custom-x"))
		assert_includes html.to_html, "custom-x"
		assert_includes html.to_html, "action-btn"
	end

	test "accepts a custom d_class and skips kind styling" do
		html = render_inline(ButtonComponent.new(kind: :delete, url: "/x", name: "x", d_class: "override"))
		assert_includes html.to_html, "override"
		refute_includes html.to_html, "hover:bg-red-200"
	end

	# ─── symbol handling ────────────────────────────
	test "bare symbol is converted to a symbol hash" do
		html = render_inline(ButtonComponent.new(kind: :action, symbol: :person))
		assert_includes html.to_html, "person"
	end

	test "kind styles compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			hover:bg-red-200 hover:bg-green-200 hover:bg-yellow-200
			hover:bg-gray-200 hover:bg-blue-100
			text-red-700 text-green-700 text-yellow-700
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

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
		assert_raises(ArgumentError) { ButtonComponent.new({}) }
	end

	# ─── class generation ───────────────────────────
	test "applies red hover classes for :delete" do
		html = render_inline(ButtonComponent.new(kind: :delete, url: "/x", name: "item")).to_html
		assert_includes html, "hover:bg-red-200"
		assert_includes html, "text-red-700"
	end

	test "applies yellow classes for :edit" do
		html = render_inline(ButtonComponent.new(kind: :edit, url: "/x")).to_html
		assert_includes html, "hover:bg-yellow-200"
		assert_includes html, "text-yellow-700"
	end

	test "applies green classes for :save" do
		html = render_inline(ButtonComponent.new(kind: :save)).to_html
		assert_includes html, "hover:bg-green-200"
		assert_includes html, "text-green-700"
	end

	test "applies blue-hover classes for :jump" do
		html = render_inline(ButtonComponent.new(kind: :jump, url: "/x", label: "Go")).to_html
		assert_includes html, "hover:bg-blue-100"
	end

	test "applies gray classes for :back" do
		html = render_inline(ButtonComponent.new(kind: :back, url: "/x")).to_html
		assert_includes html, "hover:bg-gray-200"
		assert_includes html, "text-gray-700"
	end

	test "applies filled blue classes for :login" do
		html = render_inline(ButtonComponent.new(kind: :login)).to_html
		assert_includes html, "bg-blue-900"
		assert_includes html, "text-gray-200"
		assert_includes html, "hover:bg-blue-700"
		assert_includes html, "focus:bg-blue-700"
	end

	test "applies filled gray classes for :action" do
		html = render_inline(ButtonComponent.new(kind: :action)).to_html
		assert_includes html, "bg-gray-100"
		assert_includes html, "text-gray-700"
		assert_includes html, "hover:bg-gray-300"
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
		html = render_inline(ButtonComponent.new(kind: :whatsapp, value: "666 77 88 88")).to_html
		assert_includes html, "whatsapp://send?phone=666778888"
	end

	test ":whatsapp uses the web URL when web: true" do
		html = render_inline(ButtonComponent.new(kind: :whatsapp, value: "666 77 88 88", web: true)).to_html
		assert_includes html, "https://web.whatsapp.com/send?phone=666778888"
	end

	# ─── data attributes ────────────────────────────
	test "turbo_frame defaults to _top" do
		html = render_inline(ButtonComponent.new(kind: :action)).to_html
		assert_includes html, 'turbo-frame="_top"'
	end

	test "turbo_frame can be overridden" do
		html = render_inline(ButtonComponent.new(kind: :action, frame: :modal)).to_html
		assert_includes html, 'turbo-frame="modal"'
	end

	test ":delete sets turbo_method to delete" do
		html = render_inline(ButtonComponent.new(kind: :delete, url: "/x", name: "item")).to_html
		assert_includes html, 'turbo-method="delete"'
	end

	test "submit kinds set processing controller" do
		html = render_inline(ButtonComponent.new(kind: :save)).to_html
		assert_includes html, 'controller="processing"'
	end

	# ─── labels ─────────────────────────────────────
	test "fills label from I18n for known kinds" do
		# Using with_stub to keep testing fully independent from external locale YAML files
		with_stub(I18n, :t, "Mocked Back Action") do
			html = render_inline(ButtonComponent.new(kind: :back, url: "/x")).to_html
			assert_includes html, "Mocked Back Action"
		end
	end

	test "custom label is preserved" do
		html = render_inline(ButtonComponent.new(kind: :back, url: "/x", label: "Go back")).to_html
		assert_includes html, "Go back"
	end

	# ─── custom class overrides ─────────────────────
	test "accepts a custom b_class and preserves it" do
		html = render_inline(ButtonComponent.new(kind: :action, b_class: "custom-x")).to_html
		assert_includes html, "custom-x"
		assert_includes html, "action-btn"
	end

	test "accepts a custom d_class and skips kind styling" do
		html = render_inline(ButtonComponent.new(kind: :delete, url: "/x", name: "x", d_class: "override")).to_html
		assert_includes html, "override"
		refute_includes html, "hover:bg-red-200"
	end

	# ─── symbol handling ────────────────────────────
	test "bare symbol is converted to a symbol hash" do
		html = render_inline(ButtonComponent.new(kind: :action, symbol: :person)).to_html
		assert_includes html, "person"
	end
end

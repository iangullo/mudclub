require "test_helper"

class ContactComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# ─── empty state ────────────────────────────────
	test "renders nothing when no contact fields are provided" do
		html = render_inline(ContactComponent.new).to_html
		assert_equal "", html.strip
	end

	# ─── email ──────────────────────────────────────
	test "renders an email button when email is provided" do
		html = render_inline(ContactComponent.new(email: "a@b.com")).to_html
		assert_includes html, 'href="mailto:a@b.com"'
	end

	test "does not render an email button when email is blank" do
		html = render_inline(ContactComponent.new(email: "")).to_html
		refute_includes html, "mailto:"
	end

	# ─── website ────────────────────────────────────
	test "renders a website button when website is provided" do
		html = render_inline(ContactComponent.new(website: "https://example.com")).to_html
		assert_includes html, 'href="https://example.com"'
		assert_includes html, 'target="_blank"'
	end

	test "does not render a website button when website is blank" do
		html = render_inline(ContactComponent.new(website: nil)).to_html
		refute_includes html, 'target="_blank"'
	end

	# ─── phone / call ───────────────────────────────
	test "renders a call button on mobile" do
		html = render_inline(
			ContactComponent.new(phone: "666777888", device: "mobile")
		).to_html
		assert_includes html, 'href="tel:666777888"'
	end

	test "does not render a call button on desktop" do
		html = render_inline(
			ContactComponent.new(phone: "666777888", device: "desktop")
		).to_html
		refute_includes html, "tel:666777888"
	end

	# ─── whatsapp scheme ────────────────────────────
	test "uses the web URL for whatsapp on desktop" do
		html = render_inline(
			ContactComponent.new(phone: "666777888", device: "desktop")
		).to_html
		assert_includes html, "https://web.whatsapp.com/send?phone=666777888"
		refute_includes html, "whatsapp://"
	end

	test "uses the app scheme for whatsapp on mobile" do
		html = render_inline(
			ContactComponent.new(phone: "666777888", device: "mobile")
		).to_html
		assert_includes html, "whatsapp://send?phone=666777888"
	end

	test "uses the web URL for whatsapp on tablet" do
		html = render_inline(
			ContactComponent.new(phone: "666777888", device: "tablet")
		).to_html
		assert_includes html, "https://web.whatsapp.com/"
		refute_includes html, "whatsapp://"
	end

	test "uses the web URL for whatsapp when device is unknown" do
		html = render_inline(
			ContactComponent.new(phone: "666777888", device: nil)
		).to_html
		assert_includes html, "https://web.whatsapp.com/"
		refute_includes html, "whatsapp://"
	end

	test "strips spaces from the phone number in the whatsapp URL" do
		html = render_inline(
			ContactComponent.new(phone: "666 77 88 88", device: "desktop")
		).to_html
		assert_includes html, "send?phone=666778888"
	end

	# ─── rendering order ────────────────────────────
	test "renders website, email, whatsapp in that order on desktop" do
		html = render_inline(
			ContactComponent.new(
				website: "https://example.com",
				email:   "a@b.com",
				phone:   "666777888",
				device:  "desktop"
			)
		).to_html

		website_pos = html.index("https://example.com")
		email_pos   = html.index("mailto:")
		whatsapp_pos = html.index("web.whatsapp.com")

		assert website_pos < email_pos
		assert email_pos < whatsapp_pos
	end

	test "renders all four buttons on mobile with phone and other contacts" do
		html = render_inline(
			ContactComponent.new(
				website: "https://example.com",
				email:   "a@b.com",
				phone:   "666777888",
				device:  "mobile"
			)
		).to_html

		assert_includes html, "https://example.com"
		assert_includes html, "mailto:a@b.com"
		assert_includes html, "tel:666777888"
		assert_includes html, "whatsapp://"
	end

	# ─── CSS presence ───────────────────────────────
	test "wrapper classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[inline-flex items-center text-xs].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

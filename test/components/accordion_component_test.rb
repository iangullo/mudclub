require "test_helper"

class AccordionComponentTest < ViewComponent::TestCase
	def build_accordion(section_name: "mailer", with_form: nil)
		inner_fields = FieldsComponent.new([
			[ { kind: :email_box, key: :email_from } ]
		])
		objects = [ { head: "Mailer", content: inner_fields } ]
		component = AccordionComponent.new(
			title:   "Config",
			objects: objects,
			form:    with_form
		)
		component
	end

	test "form= propagates to inner FieldsComponent" do
		fake_form = Object.new
		accordion = build_accordion
		accordion.form = fake_form

		inner = accordion.instance_variable_get(:@objects).first[:content]
		assert_equal fake_form, inner.instance_variable_get(:@form),
								"AccordionComponent#form= must propagate to its objects' content"
	end

	test "initialize with form: propagates immediately" do
		fake_form = Object.new
		accordion = build_accordion(with_form: fake_form)

		inner = accordion.instance_variable_get(:@objects).first[:content]
		assert_equal fake_form, inner.instance_variable_get(:@form),
								"form: passed at initialize must propagate to objects"
	end

	test "form= tolerates content that does not respond to form=" do
		objects = [ { head: "Static", content: "just a string" } ]
		accordion = AccordionComponent.new(title: "T", objects: objects)

		assert_nothing_raised { accordion.form = Object.new }
	end

	test "body class has no invalid Tailwind utilities" do
		html = render_inline(
			AccordionComponent.new(
				title: "T",
				objects: [ { head: "H", content: "C" } ]
			)
		).to_html

		# Assert the padding utilities that should actually be present
		assert_includes html, "py-2"
		assert_includes html, "px-2"

		# Guard against bare `py` / `px` / `p` (invalid without a number)
		refute_match(/\bclass="[^"]*\bpy\b(?![-\d])/, html)
		refute_match(/\bclass="[^"]*\bpx\b(?![-\d])/, html)
		refute_match(/\bclass="[^"]*\bp\b(?![-\d])/, html)
	end
end

# test/components/input_box_component_test.rb
require "test_helper"

class InputBoxComponentTest < ViewComponent::TestCase
	# ─── Basic input kinds (type/name contract) ──────────────

	test "text_box renders input[type=text] with the model-scoped name" do
		render_field({ kind: :text_box, key: :server_name, value: "Club" })
		assert_element "input[type=text][name='server[server_name]'][value='Club']"
	end

	test "email_box renders input[type=email]" do
		render_field({ kind: :email_box, key: :support_email, placeholder: "x@y" })
		assert_element "input[type=email][name='server[support_email]'][placeholder='x@y']"
	end

	test "password_box renders input[type=password]" do
		render_field({ kind: :password_box, key: :password })
		assert_element "input[type=password][name='server[password]']"
	end

	test "hidden renders input[type=hidden]" do
		render_field({ kind: :hidden, key: :secret, value: "abc" })
		assert_element "input[type=hidden][name='server[secret]'][value='abc']"
	end

	test "number_box renders input[type=number] with min/max defaults" do
		render_field({ kind: :number_box, key: :max_teams })
		assert_element "input[type=number][name='server[max_teams]'][min='0'][max='99']"
	end

	test "number_box honours explicit min and max" do
		render_field({ kind: :number_box, key: :age, min: 5, max: 120 })
		assert_element "input[type=number][name='server[age]'][min='5'][max='120']"
	end

	test "date_box renders input[type=date]" do
		render_field({ kind: :date_box, key: :started_on, value: Date.new(2026, 1, 1) })
		assert_element "input[type=date][name='server[started_on]']"
	end

	test "text_area renders a textarea with cols and rows" do
		render_field({ kind: :text_area, key: :email_signature, placeholder: "sig", size: 30, lines: 4 })
		assert_element "textarea[name='server[email_signature]'][placeholder='sig'][cols='30'][rows='4']"
	end

	# ─── text_box branches ───────────────────────────────────

	test "text_box with label renders a label alongside the input" do
		render_field({ kind: :text_box, key: :server_name, label: "Nombre" })
		assert_element "label"
		assert_element_with_text "label", "Nombre"
		assert_element "input[type=text][name='server[server_name]']"
	end

	test "text_box with options renders a datalist linked to the input" do
		render_field({ kind: :text_box, key: :city, options: [ "Barcelona", "Girona" ] })
		assert_element "input[type=text][list='city_list']"
		assert_element_with_text "datalist#city_list option", "Barcelona"
		assert_element_with_text "datalist#city_list option", "Girona"
	end

	test "text_area with label wraps the textarea" do
		render_field({ kind: :text_area, key: :email_signature, label: "Firma", size: 20, lines: 3 })
		assert_element_with_text "label", "Firma"
		assert_element "textarea[name='server[email_signature]']"
	end

	# ─── label_checkbox (single) ─────────────────────────────

	test "label_checkbox single: checked renders checkbox plus hidden 0" do
		render_field(
			{ kind: :label_checkbox, key: :public_clubs_enabled, label: "Clubs públics" },
			model: server_with(public_clubs_enabled: true)
		)
		assert_element "input[type=checkbox][name='server[public_clubs_enabled]'][value='1'][checked]"
		assert_element "input[type=hidden][name='server[public_clubs_enabled]'][value='0']"
		assert_element_with_text "label", "Clubs públics"
	end

	test "label_checkbox single: unchecked when the attribute is false" do
		render_field(
			{ kind: :label_checkbox, key: :public_clubs_enabled, label: "Clubs" },
			model: server_with(public_clubs_enabled: false)
		)
		assert_element "input[type=checkbox][name='server[public_clubs_enabled]']"
		refute_element "input[type=checkbox][name='server[public_clubs_enabled]'][checked]"
	end

	test "label_checkbox with right: true renders the label before the input" do
		render_field(
			{ kind: :label_checkbox, key: :public_clubs_enabled, label: "Clubs", right: true },
			model: server_with(public_clubs_enabled: false)
		)
		html = rendered_content
		assert_operator html.index(">Clubs<"), :<, html.index("type=\"checkbox\"")
	end

	# ─── label_checkbox (multiple) — the new branch ─────────
	test "label_checkbox multiple: emits name[] checkbox and no hidden 0 field" do
		render_field(
			{ kind: :label_checkbox, key: :enabled_modules, value: "admissions",
				multiple: true, label: "Admissions" },
			model: server_with(enabled_modules: [])
		)
		assert_element "input[type=checkbox][name='server[enabled_modules][]'][value='admissions']"
		# Rails deliberately omits the hidden field for multiple checkboxes,
		# so "empty array" is represented as "param absent".
		refute_element "input[type=hidden][name='server[enabled_modules][]'][value='0']"
		refute_element "input[type=hidden][name='server[enabled_modules][]'][value='']"
		assert_element_with_text "label", "Admissions"
	end

	test "label_checkbox multiple: marks checked when the value is in the model array" do
		render_field(
			{ kind: :label_checkbox, key: :enabled_modules, value: "admissions",
				multiple: true, label: "Admissions" },
			model: server_with(enabled_modules: [ "admissions" ])
		)
		assert_element "input[type=checkbox][name='server[enabled_modules][]'][value='admissions'][checked]"
	end

	test "label_checkbox multiple: unchecked when the value is absent from the array" do
		render_field(
			{ kind: :label_checkbox, key: :enabled_modules, value: "admissions",
				multiple: true, label: "Admissions" },
			model: server_with(enabled_modules: [])
		)
		refute_element "input[type=checkbox][name='server[enabled_modules][]'][checked]"
	end

	test "hidden with name: renders hidden_field_tag (for array params)" do
		render_field({ kind: :hidden, name: "server[enabled_modules][]", value: "" })
		assert_element "input[type=hidden][name='server[enabled_modules][]'][value='']"
	end

	test "hidden with key: renders form.hidden_field (backward compatible)" do
		render_field({ kind: :hidden, key: :secret, value: "x" })
		assert_element "input[type=hidden][name='server[secret]'][value='x']"
	end

	# ─── select_box ──────────────────────────────────────────

	test "select_box renders options and marks the selected one" do
		render_field(
			{ kind: :select_box, key: :default_locale,
				options: [ [ "English", :en ], [ "Català", :ca ] ],
				value: :ca }
		)
		assert_element "select[name='server[default_locale]']"
		assert_element "option[value='ca'][selected]"
		assert_element_with_text "option[value='ca']", "Català"
		assert_element_with_text "option[value='en']", "English"
		refute_element "option[value='en'][selected]"
	end

	# ─── radio_button / radio_group ──────────────────────────

	test "radio_button renders a single checked radio" do
		render_field({ kind: :radio_button, key: :mode, value: "auto", checked: true })
		assert_element "input[type=radio][name='server[mode]'][value='auto'][checked]"
	end

	test "radio_group renders one radio per option with hints" do
		render_field(
			{ kind: :radio_group, key: :mode, value: "manual",
				options: [
					{ value: "auto",   label: "Auto",   hint: "Automàtic" },
					{ value: "manual", label: "Manual", hint: nil }
				] }
		)
		assert_element "input[type=radio][name='server[mode]'][value='auto']"
		assert_element "input[type=radio][name='server[mode]'][value='manual'][checked]"
		assert_element_with_text "label", "Auto"
		assert_element_with_text "div", "Automàtic"
	end

	# ─── time_box ────────────────────────────────────────────

	test "time_box renders hour and min number fields" do
		render_field({ kind: :time_box, hour: 9, mins: 30 })
		assert_element "input[type=number][name='server[hour]'][value='9']"
		assert_element "input[type=number][name='server[min]'][value='30']"
		assert_element_with_text "strong", ":"
	end

	# ─── mandatory data-attributes (Stimulus contract) ──────

	test "mandatory presence adds data-mandatory-input and action" do
		render_field({ kind: :text_box, key: :server_name, mandatory: true })
		assert_element "input[data-mandatory-input='true']"
		assert_element "input[data-condition='presence']"
		input = element("input[type=text]")
		assert_includes input["data-action"].to_s, "mandatory#check"
	end

	test "mandatory length produces the length condition" do
		render_field({ kind: :text_box, key: :server_name, mandatory: { length: 3 } })
		assert_element "input[data-condition='length:3']"
	end

	test "mandatory min/max build a combined condition string" do
		render_field({ kind: :text_box, key: :server_name, mandatory: { min: 2, max: 30 } })
		assert_element "input[data-condition='min:2;max:30']"
	end

	test "mandatory preserves existing data-action" do
		render_field(
			{ kind: :text_box, key: :server_name, mandatory: true,
				i_data: { action: "existing#action" } }
		)
		action = element("input[type=text]")["data-action"].to_s
		assert_includes action, "existing#action"
		assert_includes action, "mandatory#check"
	end

	# ─── select_collection ──────────────────────────────────

	test "select_collection renders a plain select with one option per entry" do
		render_field(
			{ kind: :select_collection, key: :team_id,
				options: [ { id: 1, name: "A" }, { id: 2, name: "B" } ],
				value: 2 }
		)
		assert_element "select[name='server[team_id]']"
		assert_element "option[value='1']"
		assert_element_with_text "option[value='1']", "A"
		assert_element "option[value='2'][selected]"
		assert_element_with_text "option[value='2']", "B"
	end

	# ─── select_load ────────────────────────────────────────

	test "select_load renders a select inside a fieldset with the turbo anchor" do
		render_field(
			{ kind: :select_load, key: :drill_id,
				options: [ [ "Drill A", 1 ], [ "Drill B", 2 ] ],
				value: 1, url: "/drills" }
		)
		assert_element "fieldset[data-controller='search-params select-load']"
		assert_element "select[name='server[drill_id]']"
		assert_element "option[value='1'][selected]"
		assert_element "a[href='/drills'][hidden][data-search-params-target='anchor']"
	end

	# ─── upload ─────────────────────────────────────────────

	test "upload renders a hidden file input and a trigger button" do
		render_field(
			{ kind: :upload, key: :picture, label: "Pujar",
				value: "logo.png", accept: "image/*" }
		)
		assert_element "input[type=file][name='server[picture]'][accept='image/*']"
		assert_element_with_text "button", "Pujar"
		assert_element_with_text "span#file-name-picture", "logo.png"
	end

	test "upload with no value shows the no-file label" do
		render_field({ kind: :upload, key: :picture, label: "Pujar" })
		assert_element_with_text "span#file-name-picture", I18n.t("status.no_file")
	end

	# ─── image_box ──────────────────────────────────────────

	test "image_box with nil value renders the placeholder and the file input" do
		render_field({ kind: :image_box, key: :logo, value: nil })
		assert_element "#imageboxContainer"
		assert_element "#imageFile[type=file]"
		refute_element "#imageSnapshot"
	end

	private

	# ─── FormBuilder setup ──────────────────────────────────

	def form_builder_for(model)
		ActionView::Helpers::FormBuilder.new(
			model.model_name.param_key,
			model,
			vc_test_controller.view_context,
			{}
		)
	end

	def render_field(field, model: server_with)
		render_inline(InputBoxComponent.new(field, form: form_builder_for(model)))
	end

	def server_with(settings = {})
		Server.new(settings: settings)
	end

	# ─── Nokogiri-based assertions ──────────────────────────

	def doc
		@doc ||= Nokogiri::HTML.fragment(rendered_content)
	end

	def element(selector)
		doc.at_css(selector)
	end

	def elements(selector)
		doc.css(selector)
	end

	def assert_element(selector)
		node = element(selector)
		assert node, "expected to find element matching #{selector.inspect}, in:\n#{rendered_content}"
		node
	end

	def refute_element(selector)
		assert_nil element(selector),
							"expected NOT to find element matching #{selector.inspect}, but found it in:\n#{rendered_content}"
	end

	def assert_element_count(selector, count)
		assert_equal count, elements(selector).size,
								"expected #{count} elements matching #{selector.inspect}, got #{elements(selector).size} in:\n#{rendered_content}"
	end

	def assert_element_with_text(selector, text)
		nodes = elements(selector)
		assert nodes.any?, "expected to find at least one #{selector.inspect}, got none in:\n#{rendered_content}"
		assert nodes.any? { |n| n.text.to_s.strip == text.to_s.strip || n.text.to_s.include?(text.to_s) },
					"expected a node matching #{selector.inspect} to contain #{text.inspect}, got: " \
					"#{nodes.map { |n| n.text.to_s.strip.inspect }.join(', ')}"
	end
end

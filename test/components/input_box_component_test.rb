require "test_helper"

class InputBoxComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	SAMPLE_DATA = {
		radio_group:       [ { value: "a", label: "A" } ],
		select_box:        %w[a b],
		select_collection: [ { id: "a", name: "A" } ],
		select_load:       [ %w[a A] ],
		select_checkboxes: [ Struct.new(:id, :name).new(1, "A"),
												Struct.new(:id, :name).new(2, "B") ],
		text_box:          %w[a b]
	}.freeze

	# Minimal model that responds to any attribute the field kinds ask for.
	class TestFormModel
		include ActiveModel::Model
		attr_accessor :id, :nick, :email, :birthday, :active, :x, :notes,
									:avatar, :color, :item_id, :pwd, :age, :hour, :min, :size

		def self.model_name
			ActiveModel::Name.new(self, nil, "Drill")
		end
	end

	def form_builder(model = TestFormModel.new)
		controller = ApplicationController.new
		controller.request = ActionDispatch::TestRequest.create
		ActionView::Helpers::FormBuilder.new(model.model_name.param_key, model, controller.view_context, {})
	end

	def render_input(**field)
		render_inline(InputBoxComponent.new(field, form: form_builder)).to_html
	end

	# ─── :text_box ──────────────────────────────────
	test "text_box renders a text input" do
		html = render_input(kind: :text_box, key: :nick, value: "x")
		assert_match(/<input[^>]*type="text"/, html)
		assert_includes html, 'value="x"'
	end

	test "text_box with label wraps the input" do
		html = render_input(kind: :text_box, key: :nick, value: "x", label: "Nick")
		assert_includes html, "Nick"
		assert_match(/<label[^>]*font-semibold/, html)
	end

	test "text_box with options renders a datalist" do
		html = render_input(kind: :text_box, key: :nick, options: %w[a b])
		assert_match(/<datalist/, html)
		assert_includes html, ">a<"
		assert_includes html, ">b<"
	end

	# ─── :email_box ─────────────────────────────────
	test "email_box renders an email input with placeholder" do
		html = render_input(kind: :email_box, key: :email, placeholder: "a@b.c")
		assert_match(/<input[^>]*type="email"/, html)
		assert_includes html, 'placeholder="a@b.c"'
	end

	# ─── :password_box ──────────────────────────────
	test "password_box renders a password input" do
		html = render_input(kind: :password_box, key: :pwd)
		assert_match(/<input[^>]*type="password"/, html)
	end

	# ─── :number_box ────────────────────────────────
	test "number_box renders a number input with min and max" do
		html = render_input(kind: :number_box, key: :age, value: 5)
		assert_match(/<input[^>]*type="number"/, html)
		assert_includes html, 'min="0"'
		assert_includes html, 'max="99"'
	end

	test "number_box respects custom min and max" do
		html = render_input(kind: :number_box, key: :age, min: 10, max: 20)
		assert_includes html, 'min="10"'
		assert_includes html, 'max="20"'
	end

	# ─── :date_box ──────────────────────────────────
	test "date_box renders a date input with min and max" do
		html = render_input(kind: :date_box, key: :birthday,
												s_year: 1950, e_year: 2026)
		assert_match(/<input[^>]*type="date"/, html)
		assert_includes html, 'min="1950-01-01"'
		assert_includes html, 'max="2026-12-31"'
	end

	test "date_box omits min when s_year is not set" do
		html = render_input(kind: :date_box, key: :birthday, e_year: 2026)
		refute_match(/min="\d{4}-01-01"/, html)
		assert_includes html, 'max="2026-12-31"'
	end

	# ─── :hidden ────────────────────────────────────
	test "hidden with :name uses hidden_field_tag" do
		html = render_input(kind: :hidden, name: "token", value: "abc")
		assert_match(/<input[^>]*type="hidden"/, html)
		assert_includes html, 'name="token"'
		assert_includes html, 'value="abc"'
	end

	test "hidden without :name uses the form builder" do
		html = render_input(kind: :hidden, key: :id, value: "42")
		assert_match(/<input[^>]*type="hidden"/, html)
		assert_includes html, 'name="drill[id]"'
	end

	# ─── :label_checkbox ────────────────────────────
	test "label_checkbox renders a checkbox and its label" do
		html = render_input(kind: :label_checkbox, key: :active, label: "Active")
		assert_match(/<input[^>]*type="checkbox"/, html)
		assert_includes html, "Active"
	end

	# ─── :radio_button / :radio_group ───────────────
	test "radio_button renders a single radio input" do
		html = render_input(kind: :radio_button, key: :color, value: "red")
		assert_match(/<input[^>]*type="radio"/, html)
		assert_includes html, 'value="red"'
	end

	test "radio_group renders one radio per option" do
		html = render_input(
			kind: :radio_group, key: :color, value: "red",
			options: [
				{ value: "red",   label: "Red" },
				{ value: "blue",  label: "Blue", hint: "Cool" }
			]
		)
		assert_equal 2, html.scan(/type="radio"/).size
		assert_includes html, "Red"
		assert_includes html, "Blue"
		assert_includes html, "Cool"
	end

	# ─── :select_box / :select_collection ───────────
	test "select_box renders a select with options" do
		html = render_input(kind: :select_box, key: :size,
												options: %w[small medium large], value: "medium")
		assert_match(/<select/, html)
		assert_equal 3, html.scan(/<option/).size
		assert_includes html, 'selected="selected"'
	end

	test "select_collection renders one option per object" do
		options = [
			{ id: 1, name: "One" },
			{ id: 2, name: "Two" }
		]
		html = render_input(kind: :select_collection, key: :item_id,
												options: options, value: 2)
		assert_match(/<select/, html)
		assert_equal 2, html.scan(/<option/).size
		assert_match(/<option value="2" selected="selected"/, html)
	end

	# ─── :text_area ─────────────────────────────────
	test "text_area renders a textarea" do
		html = render_input(kind: :text_area, key: :notes, value: "hello")
		assert_match(/<textarea/, html)
		assert_includes html, "hello"
	end

	# ─── :upload ────────────────────────────────────
	test "upload renders a hidden file input and a trigger button" do
		html = render_input(kind: :upload, key: :avatar, label: "Choose file")
		input = parsed(html).css('input[type="file"]').first

		refute_nil input, "expected a file input"
		assert_includes input["class"].to_s, "hidden"
		assert_includes html, "Choose file"
		assert_includes html, 'data-action="click->upload#selectFile"'
	end

	test "upload renders the filename span" do
		html = render_input(kind: :upload, key: :avatar, value: nil)
		assert_match(/data-upload-target="fileName"/, html)
		assert_includes html, I18n.t("status.no_file")
	end

	# ─── :image_box ─────────────────────────────────
	test "image_box sanitizes non-attachment string values" do
		html = render_input(kind: :image_box, key: :avatar, value: "/path/to/img.png")
		doc  = parsed(html)
		img  = doc.css('img[data-imagebox-target="selectedImage"]').first

		refute_nil img
		assert_equal "", img["src"].to_s, "string values are sanitized to blank"
		refute_nil doc.css('[data-imagebox-target="placeholder"]').first,
			"placeholder should render when value is sanitized away"
	end

	test "image_box renders the style block with the requested size" do
		html = render_input(kind: :image_box, key: :avatar, size: "100x150")
		assert_includes html, "width: 100px"
		assert_includes html, "height: 150px"
		assert_includes html, "max-width: 100px"
		assert_includes html, "max-height: 150px"
	end

	test "image_box honors :width and :height overrides" do
		html = render_input(kind: :image_box, key: :avatar,
												width: 200, height: 300)
		assert_includes html, "width: 200px"
		assert_includes html, "height: 300px"
	end

	test "image_box renders a placeholder when value is blank" do
		html = render_input(kind: :image_box, key: :avatar, value: nil)

		assert_match(/data-controller="imagebox"/, html)
		assert_includes html, "📷"
		refute_nil parsed(html).css('input[type="file"]').first
	end

	test "image_box with blank value renders a hidden img target for the placeholder path" do
		html = render_input(kind: :image_box, key: :avatar, value: nil)
		doc  = parsed(html)
		img  = doc.css('img[data-imagebox-target="selectedImage"]').first

		refute_nil img, "expected an <img> target for FileReader"
		assert_includes img["class"].to_s, "hidden"
		refute_nil doc.css('[data-imagebox-target="placeholder"]').first,
			"expected a placeholder target"
	end

	test "image_box renders placeholder symbol hidden via CSS when value is blank" do
		html = render_input(kind: :image_box, key: :avatar, value: nil)
		assert_includes html, "hidden"       # the empty img is hidden initially
	end

	# ─── :time_box ──────────────────────────────────
	test "time_box renders two number inputs separated by a colon" do
		html = render_input(kind: :time_box, hour: 9, mins: 30)
		assert_equal 2, html.scan(/type="number"/).size
		assert_includes html, "<strong>:</strong>"
	end

	test "time_box defaults to min:9;max:22 on hour and min:0;max:45 on minutes" do
		html   = render_input(kind: :time_box, hour: 10, mins: 30, mandatory: true)
		inputs = parsed(html).css('input[type="number"]')

		assert_equal 2, inputs.size
		assert_equal "min:9;max:22", inputs[0]["data-condition"]
		assert_equal "min:0;max:45", inputs[1]["data-condition"]
	end

	test "time_box hour_condition and min_condition overrides apply per field" do
		html = render_input(kind: :time_box, hour: 10, mins: 30, mandatory: true,
												hour_condition: "min:14;max:18",
												min_condition:  "min:15;max:45")
		assert_includes html, 'data-condition="min:14;max:18"'
		assert_includes html, 'data-condition="min:15;max:45"'
		refute_includes html, "min:9;max:22"
	end

	test "time_box without mandatory does not set data-mandatory-input" do
		html = render_input(kind: :time_box, hour: 10, mins: 30)
		refute_includes html, 'data-mandatory-input="true"'
	end

	test "time_box with mandatory sets data-mandatory-input on both sub-fields" do
		html = render_input(kind: :time_box, hour: 10, mins: 30, mandatory: true)
		assert_equal 2, html.scan(/data-mandatory-input="true"/).size
	end

	# ─── mandatory wiring ───────────────────────────
	test "mandatory field gets data-mandatory-input and a condition" do
		html = render_input(kind: :text_box, key: :nick,
												mandatory: { length: 3 })
		assert_includes html, 'data-mandatory-input="true"'
		assert_includes html, 'data-condition="length:3"'
	end

	test "mandatory with unless emits mandatory_unless" do
		html = render_input(kind: :text_box, key: :nick,
												mandatory: { length: 3, unless: [ :guardian ] })
		assert_includes html, "data-mandatory-unless"
		assert_includes html, "guardian"
	end

	test "date_box mandatory emits date_min/date_max conditions" do
		html = render_input(kind: :date_box, key: :birthday,
												mandatory: { min: "1950-01-01", max: "2026-12-31" })
		assert_includes html, 'data-condition="date_min:1950-01-01;date_max:2026-12-31"'
	end

	# ─── CSS hygiene ────────────────────────────────
	test "no kind emits a bare 'px' or 'py' class" do
		kinds = %i[text_box email_box password_box number_box date_box
							text_area radio_group label_checkbox upload
							select_box select_collection select_load select_checkboxes]

		kinds.each do |kind|
			html = render_input(
				kind:    kind,
				key:     :x,
				value:   "y",
				label:   "L",
				options: SAMPLE_DATA[kind]
			)
			refute_match(/\bclass="[^"]*\bpx\b(?![-\w])/, html, "kind #{kind} emits bare px")
			refute_match(/\bclass="[^"]*\bpy\b(?![-\w])/, html, "kind #{kind} emits bare py")
		end
	end

	test "all InputBox classes compile in the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			rounded py-0 px-1 inset-shadow-sm border border-gray-200
			bg-gray-50 focus:ring-blue-700
			align-middle m-1 bg-gray-200 text-blue-700
			text-black text-right
			overflow-hidden overflow-ellipsis
			inline-flex items-center rounded-md shadow bg-gray-100
			ring-2 ring-gray-300 hover:bg-gray-300 focus:border-gray-300
			font-semibold text-sm px-1 py-1 justify-center
			object-cover w-full text-4xl pointer-events-none
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls}"
		end
	end
end

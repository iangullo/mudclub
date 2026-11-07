require "test_helper"

class SortableComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def setup
		@drill = Drill.new
		@drill.steps.build(order: 1, svgdata: {})
		@drill.steps.build(order: 2, svgdata: {})
	end

	def form_builder(model = @drill)
		controller = ApplicationController.new
		controller.request  = ActionDispatch::TestRequest.create
		controller.response = ActionDispatch::TestResponse.new
		ActionView::Helpers::FormBuilder.new(
			model.model_name.param_key, model, controller.view_context, {}
		)
	end

	def render_sortable(drill: @drill, key: :steps, order: :order, row: "drills/step_row")
		render_inline(
			SortableComponent.new(form: form_builder(drill), key:, order:, row:)
		).to_html
	end

	def sortable_div(html)
		parsed(html).css("[data-controller='sortable']").first
	end

	test "model wiring" do
	d = Drill.new
	d.steps.build(order: 1, svgdata: {})
	assert d.steps.size == 1
	assert Drill.nested_attributes_options.key?(:steps)
end

	# ─── wrapper element ────────────────────────────
	test "renders a <turbo-frame> element (with a dash)" do
		html  = render_sortable
		frame = parsed(html).css("turbo-frame").first

		refute_nil frame, "expected a <turbo-frame> element, got something else"
		assert_equal "sortable-steps", frame["id"]
		assert_includes frame["class"].to_s, "contents"
	end

	test "does not emit an invalid <turbo_frame> element" do
		html = render_sortable
		refute_match(/<turbo_frame\b/, html,
			"content_tag(:turbo_frame, …) renders the wrong element; use turbo_frame_tag")
	end

	test "explicit id: overrides the derived wrapper id" do
		html  = render_inline(
			SortableComponent.new(
				form:  form_builder,
				key:   :steps,
				order: :order,
				row:   "drills/step_row",
				id:    "custom-sortable"
			)
		).to_html
		frame = parsed(html).css("turbo-frame").first
		assert_equal "custom-sortable", frame["id"]
	end

	# ─── sortable controller ────────────────────────
	test "inner div carries the sortable Stimulus controller" do
		html = render_sortable
		div  = sortable_div(html)

		refute_nil div
		assert_equal "150", div["data-sortable-animation-value"]
	end

	test "inner div uses a single-column grid layout" do
		div = sortable_div(render_sortable)
		assert_includes div["style"].to_s, "grid-template-columns: 1fr"
	end

	# ─── rows ───────────────────────────────────────
	test "renders one row wrapper per child" do
		rows = sortable_div(render_sortable).css("> div")
		assert_equal 2, rows.size
	end

	test "each row has the draggable class (required by the JS controller)" do
		rows = sortable_div(render_sortable).css("> div")
		rows.each do |row|
			assert_includes row["class"].to_s, "draggable",
				"draggable class must be present — sortable_controller uses closest('.draggable')"
		end
	end

	test "each row has the styled background class" do
		rows = sortable_div(render_sortable).css("> div")
		rows.each do |row|
			assert_includes row["class"].to_s, "bg-gray-100"
			assert_includes row["class"].to_s, "rounded-md"
		end
	end

	# ─── hidden fields ──────────────────────────────
	test "each row includes id, _destroy, and order hidden fields" do
		rows = sortable_div(render_sortable).css("> div")
		rows.each do |row|
			names = row.css('input[type="hidden"]').map { |i| i["name"] }
			assert names.any? { |n| n.end_with?("[id]")       }, "missing [id] hidden field"
			assert names.any? { |n| n.end_with?("[_destroy]") }, "missing [_destroy] hidden field"
			assert names.any? { |n| n.end_with?("[order]")    }, "missing [order] hidden field"
		end
	end

	test "hidden fields follow the nested association naming convention" do
		html = render_sortable
		# Each row should have drill[steps_attributes][N][id], [_destroy], [order]
		%w[id _destroy order].each do |field|
			assert_match(
				/name="drill\[steps_attributes\]\[\d+\]\[#{field}\]"/,
				html,
				"missing field name pattern drill[steps_attributes][N][#{field}]"
			)
		end
	end

	# ─── partial rendering ──────────────────────────
	test "each row renders the given partial" do
		rows = sortable_div(render_sortable).css("> div")

		assert_equal 2, rows.size

		rows.each_with_index do |row, i|
			# the partial injected at least one element beyond the three
			# hidden inputs the component emits (id / _destroy / order)
			non_hidden = row.element_children.reject { |el|
				el.name == "input" && el["type"] == "hidden"
			}
			assert non_hidden.any?,
				"row #{i}: drills/_row.html.erb produced no markup (only hidden fields)"
		end
	end

	# ─── empty collection ───────────────────────────
	test "renders the wrapper when the collection is empty" do
		empty = Drill.new
		html  = render_sortable(drill: empty)
		div   = sortable_div(html)

		refute_nil div
		assert_equal 0, div.css("> div").size
	end

	test "works with an unsaved parent (Array rather than ActiveRecord::Relation)" do
		# Drill.new.steps is an Array; the .order guard must skip ordering
		html = render_sortable
		refute_nil sortable_div(html),
			"component should render for unsaved parents"
	end

	# ─── event tasks  ──────────────────────────────
	test "renders the tasks association when key: :tasks is passed" do
		event = events(:train_north)   # persisted: has club, team, and 2 tasks

		html = render_inline(
			SortableComponent.new(
				form:  form_builder(event),
				key:   :tasks,
				order: :order,
				row:   "events/task_row"
			)
		).to_html

		frame = parsed(html).css("turbo-frame").first
		refute_nil frame
		assert_equal "sortable-tasks", frame["id"]
		assert_equal 2, frame.css("[data-controller='sortable'] > div").size

		# bonus: pin the route the partial builds
		edit_hrefs = frame.css("[data-controller='sortable'] > div a[href*='edit_task']")
		assert_equal 2, edit_hrefs.size
		edit_hrefs.each do |a|
			assert_match %r{/clubs/#{clubs(:north).id}/teams/#{teams(:north_senior).id}/events/#{event.id}/edit_task\?task_id=\d+},
									a["href"]
		end
	end

	# ─── render? guard ──────────────────────────────
	test "renders nothing when form is nil" do
		html = render_inline(
			SortableComponent.new(form: nil, key: :steps, order: :order, row: "drills/step_row", id: "custom_sortable")
		).to_html
		assert_equal "", html.strip
	end

	# ─── id uniqueness (if you applied the per-key id fix) ──
	test "wrapper id is derived from the association key" do
		html  = render_sortable(key: :skills, row: "drills/skill_row")
		frame = parsed(html).css("turbo-frame").first

		refute_nil frame
		assert_equal "sortable-skills", frame["id"]
	end

	# ─── CSS presence ───────────────────────────────
	test "row classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			bg-gray-100 text-left text-gray-700 rounded-md
			hover:bg-gray-500 hover:text-indigo-100
			contents
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls}"
		end
	end
end

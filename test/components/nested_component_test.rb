require "test_helper"

class NestedComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	def setup
		@drill = Drill.new
		@drill.skills << Skill.new(concept: "Dribbling")
		@drill.skills << Skill.new(concept: "Passing")
	end

	def form_builder(model = @drill)
		controller = ApplicationController.new
		controller.request  = ActionDispatch::TestRequest.create
		controller.response = ActionDispatch::TestResponse.new
		ActionView::Helpers::FormBuilder.new(
			model.model_name.param_key, model, controller.view_context, {}
		)
	end

	def render_nested(drill: @drill, filter: nil, order: nil)
		render_inline(
			NestedComponent.new(
				model:  drill.model_name.param_key,
				key:    :skills,
				form:   form_builder(drill),
				child:  Skill.new,
				row:    "drills/skill_row",
				filter: filter,
				order:  order
			)
		).to_html
	end

	def container(html)
		parsed(html).css('[data-nested-form-target="container"]').first
	end

	# ─── structure ──────────────────────────────────
	test "renders the wrapper with a stable DOM id" do
		html = render_nested
		assert_match(/<div[^>]*id="drill-skills"/, html)
	end

	test "wrapper carries the nested-form Stimulus controller" do
		html = render_nested
		assert_includes html, 'data-controller="nested-form"'
	end

	test "renders one placeholder row inside the template" do
		html     = render_nested
		template = parsed(html).css('template[data-nested-form-target="template"]').first

		refute_nil template, "expected a <template> for new records"
	end

	# ─── container rows ─────────────────────────────
	test "renders one row per existing skill" do
		html = render_nested
		c    = container(html)

		refute_nil c, "expected a container div"
		assert_equal 2, c.css('[data-nested-form-target="item"]').size
	end

	test "each real row renders a remove button" do
		html = render_nested
		c    = container(html)

		refute_nil c
		assert_equal 2, c.css(".remove-btn").size
	end

	test "renders the skill concept values" do
		html = render_nested
		assert_includes html, 'value="Dribbling"'
		assert_includes html, 'value="Passing"'
	end

	# ─── filter ─────────────────────────────────────
	test "filter keeps only matching skills" do
		html = render_nested(filter: { concept: "Dribbling" })
		assert_includes html, "Dribbling"
		refute_includes html, "Passing"
	end
end

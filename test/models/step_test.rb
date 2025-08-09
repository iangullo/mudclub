require "test_helper"

class StepTest < ActiveSupport::TestCase
	test "should be valid with required attributes" do
		step = Step.new(drill: drills(:one), order: 1)
		assert step.valid?
	end

	test "should require order" do
		step = Step.new(drill: drills(:one))
		assert_not step.valid?
		assert_includes step.errors[:order], "can't be blank"
	end

	test "should determine kind correctly" do
		step = Step.new(drill: drills(:one), order: 1)
		assert_equal :empty, step.kind

		step.explanation = "Some text"
		assert_equal :text, step.kind

		step.diagram.attach(io: File.open("test/fixtures/files/sample.png"), filename: "sample.png", content_type: "image/png")
		assert_equal :combo_image, step.kind

		step.diagram.purge
		step.diagram_svg = "<svg></svg>"
		assert_equal :combo_svg, step.kind

		step.explanation = nil
		assert_equal :svg, step.kind

		step.diagram_svg = nil
		step.diagram.attach(io: File.open("test/fixtures/files/sample.png"), filename: "sample.png", content_type: "image/png")
		assert_equal :image, step.kind
	end
end

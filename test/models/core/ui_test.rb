require "test_helper"

class UITest < ActiveSupport::TestCase
	test "resolves known UI concepts dynamically and caches constant classes" do
		UI::CONCEPTS.each_key do |concept|
			next if Object.const_defined?(concept)

			klass = UI.const_get(concept)
			assert klass < UI::Base, "Expected UI::#{concept} to inherit from UI::Base"
			assert_same klass, UI.const_get(concept)
		end
	end


	test "raises NameError for unknown UI constants" do
		assert_raises(NameError) { UI::NonExistentConcept }
	end
end

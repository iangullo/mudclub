require "test_helper"

# Kinded is exercised through Event, which uses Catalog::EventKinds.
# These tests lock the concern's contract independently of any consumer
# (EventCalendar, forms, views) so regressions surface here first.
class KindedTest < ActiveSupport::TestCase
	setup do
		@locale     = I18n.locale
		I18n.locale = :en
	end

	teardown { I18n.locale = @locale }

	# ----- catalog wiring ------------------------------------------------

	test "kind_catalog is derived by convention" do
		assert_equal Catalog::EventKinds, Event.kind_catalog
	end

	test "enum includes canonical kinds and deprecated aliases" do
		kinds = Event.kinds
		assert_equal 1, kinds["training"]
		assert_equal 1, kinds["train"]      # alias of training, same id
		assert_equal 0, kinds["holiday"]
		assert_equal 0, kinds["rest"]       # alias of holiday
		assert_equal 2, kinds["match"]
	end

	# ----- label resolution ---------------------------------------------

	test "kind_label delegates to the catalog's localized value" do
		assert_equal Event.kind_catalog.val(:training), Event.kind_label(:training)
		assert_equal Event.kind_catalog.val(:holiday),  Event.kind_label(:holiday)
		assert_equal Event.kind_catalog.val(:match),    Event.kind_label(:match)
	end

	test "kind_label resolves deprecated aliases to the canonical label" do
		assert_equal Event.kind_label(:training), Event.kind_label(:train)
		assert_equal Event.kind_label(:holiday),  Event.kind_label(:rest)
	end

	test "kind_label returns a non-blank string for every canonical kind" do
		%i[holiday training match meeting social competition other].each do |kind|
			label = Event.kind_label(kind)
			assert label.present?, "expected a label for #{kind.inspect}"
			assert_kind_of String, label
		end
	end

	test "kind_label is nil-safe" do
		assert_nil Event.kind_label(nil)
	end

	# ----- instance reader ----------------------------------------------

	test "kind reader returns the canonical symbol regardless of how it was set" do
		assert_equal :training, Event.new(kind: :train).kind
		assert_equal :training, Event.new(kind: :training).kind
		assert_equal :holiday,  Event.new(kind: :rest).kind
		assert_equal :holiday,  Event.new(kind: :holiday).kind
		assert_equal :match,    Event.new(kind: :match).kind
	end

	test "kind_label on an instance matches the class method" do
		event = Event.new(kind: :train)
		assert_equal Event.kind_label(:training), event.kind_label
	end

	# ----- scopes (SQL-level, no DB dependency) -------------------------

	test "of_kind accepts canonical kinds and aliases, mapping them to the same id" do
		canonical_sql = Event.where(kind: 1).to_sql
		assert_equal canonical_sql, Event.of_kind(:training).to_sql
		assert_equal canonical_sql, Event.of_kind(:train).to_sql
		assert_equal canonical_sql, Event.of_kind(%i[train training]).to_sql
		assert_equal Event.all.to_sql, Event.of_kind(nil).to_sql
		assert_equal Event.all.to_sql, Event.of_kind([]).to_sql
	end

	# ----- option helpers -----------------------------------------------

	test "kind_list excludes deprecated aliases by default" do
		keys = Event.kind_list.map(&:last)
		assert_includes keys, :training
		refute_includes keys, :train
		refute_includes keys, :rest
	end

	test "kind_list exposes aliases when asked" do
		keys = Event.kind_catalog.option_list(include_deprecated: true).map(&:last)
		assert_includes keys, :train
		assert_includes keys, :rest
	end

	test "kind_image defaults to :missing for unknown kinds" do
		assert_equal({ symbol: :missing }, Event.kind_image(:not_a_kind))
		refute_equal :missing, Event.kind_image(:training)[:symbol]
	end

	test "kind_gender defaults to nil" do
		assert_nil Event.new.kind_gender
	end
end

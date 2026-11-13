# test/test_helper.rb
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "capybara/rails"
require "nokogiri"

class ActiveSupport::TestCase
	# Run tests in parallel with specified workers
	parallelize(workers: :number_of_processors)

	# Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
	fixtures :all

	def parsed(html)
		Nokogiri::HTML.fragment(html)
	end

	# minitest/mock style Stub to avoid adding dependency of minitest/mock.
	# Use:  with_stub(Rails.application.config, :cache_store, :solid_cache_store) { ... }
	def with_stub(receiver, method_name, value)
		original = receiver.method(method_name) rescue nil
		receiver.define_singleton_method(method_name) { |*_args, **_kwargs, &_blk| value }
		yield
	ensure
		if original
			receiver.define_singleton_method(method_name, original)
		else
			receiver.singleton_class.send(:remove_method, method_name)
		end
	end
end

class FakeEvent
	attr_reader :kind, :name, :date_string

	def initialize(kind:, name: "Test", date_string: "15/01/2026", label: nil)
		@kind        = kind
		@name        = name
		@date_string = date_string
		@label       = label
	end

	def kind_label
		@label || Catalog::EventKinds.fetch(@kind).label
	end

	def to_s(style: nil)
		base  = @label
		base += ": #{@name}" if holiday_name_applies?
		style == "notice" ? "#{base} (#{@date_string})" : base
	end

	private
		def holiday_name_applies?
			@kind.to_s.in?(%w[holiday rest]) && @name.present? && @name != kind_label
		end
end

# test/system/button_confirmation_test.rb
require "application_system_test_case"

class ButtonConfirmationTest < ApplicationSystemTestCase
	class TestHarnessController < ApplicationController
		skip_before_action :authenticate_user!, raise: false

		def show
			render inline: <<~ERB, layout: "application"
				<%= form_with url: "/_test_button_submit", method: :post do %>
					<%= render ButtonComponent.new(kind: :save) %>
				<% end %>

				<%= form_with url: "/_test_button_submit", method: :post do %>
					<%= render ButtonComponent.new(kind: :import) %>
				<% end %>

				<%= render ButtonComponent.new(kind: :delete, url: "/_test_button_submit", name: "Test Item") %>
				<%= render ButtonComponent.new(kind: :anonymize, url: "/_test_button_submit", name: "Test Item") %>
				<%= render ButtonComponent.new(kind: :clear, url: "/_test_button_submit", name: "Test Item") %>
			ERB
		end
	end

	setup do
		Rails.application.routes.append do
			get "/_test_button_confirmation" => "button_confirmation_test/test_harness#show"
			match "/_test_button_submit" => "button_confirmation_test/test_harness#show", via: %i[post patch delete]
		end
		Rails.application.routes_reloader.execute_if_updated
	end

	teardown do
		Rails.application.reload_routes!
	end

	%w[save-btn import-btn delete-btn anonymize-btn clear-btn].each do |btn_class|
		test "clicking .#{btn_class} triggers window.confirm only once" do
			visit "/_test_button_confirmation"

			page.execute_script(<<~JS)
				window.__confirmCount = 0;
				window.confirm = () => { window.__confirmCount += 1; return false; };
			JS

			find(".#{btn_class}").click

			Timeout.timeout(Capybara.default_max_wait_time) do
				sleep 0.05 until page.evaluate_script("window.__confirmCount") >= 1
			end rescue Timeout::Error

			sleep 0.1

			assert_equal 1, page.evaluate_script("window.__confirmCount"),
				"Expected exactly 1 confirmation dialog for .#{btn_class}, got #{page.evaluate_script('window.__confirmCount')}"
		end
	end
end

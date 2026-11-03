require "test_helper"

class CalendarComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	setup do
		@club     = clubs(:test_club)
		@team     = teams(:senior_a)
		@location = locations(:home_court)
		@start    = Date.current.beginning_of_month
	end

	def build_component(events: [], obj: @team, create_url: nil,
											start_date: @start, user: @user)
		CalendarComponent.new(
			anchor:     { url: "/clubs/#{@club.id}/teams/#{@team.id}/events" },
			obj:        obj,
			start_date: start_date,
			user:       user,
			create_url: create_url,
			events:     events
		)
	end

	def make_event(kind:, offset_days: 3, **extra)
		Event.create!(
			club:       @club,
			team:       @team,
			location:   @location,
			start_time: @start + offset_days.days,
			end_time:		@start + offset_days.days + 120.minutes,
			kind:       kind,
			**extra
		)
	end

	# ─── basic structure ────────────────────────────
	test "renders the month and year in the header" do
		html = render_inline(build_component).to_html
		assert_includes html, I18n.t("calendar.monthnames")[@start.month]
		assert_includes html, @start.year.to_s
	end

	test "renders day names for each column" do
		html = render_inline(build_component).to_html
		I18n.t("calendar.daynames_a")[1..7].each do |day|
			assert_includes html, day
		end
	end

	test "renders each day of the month" do
		html = render_inline(build_component).to_html
		(1..@start.end_of_month.day).each do |day|
			assert_match(/>\s*#{day}\s*</, html)
		end
	end

	# ─── back / forward buttons ─────────────────────
	test "back button is absent at the beginning of the season" do
		start = @team.season.start_date.beginning_of_month
		html  = render_inline(build_component(start_date: start)).to_html
		refute_includes html, "start_date=#{(start - 1.month)}"
	end

	test "back button is present mid-season" do
		start = (@team.season.start_date + 1.month).beginning_of_month
		html  = render_inline(build_component(start_date: start)).to_html
		assert_includes html, "start_date=#{(start - 1.month)}"
	end

	test "forward button is absent at the end of the season" do
		start = @team.season.end_date.beginning_of_month
		html  = render_inline(build_component(start_date: start)).to_html
		refute_includes html, "start_date=#{(start + 1.month)}"
	end

	test "forward button is present mid-season" do
		start = (@team.season.start_date + 1.month).beginning_of_month
		html  = render_inline(build_component(start_date: start)).to_html
		assert_includes html, "start_date=#{(start + 1.month)}"
	end

	# ─── event styling ──────────────────────────────
	test "match event renders with green class when home wins" do
		event = make_event(kind: :match, offset_days: 3, home: true, name: "vs Rivals")
		def event.total_score
			{ ours: { points: 80, team: "TC" }, opps: { points: 70, team: "Rivals" } }
		end

		html = render_inline(build_component(events: [ event ])).to_html
		assert_includes html, "bg-green-300"
		assert_includes html, "hover:bg-green-700"
	end

	test "match event renders with red class when home loses" do
		event = make_event(kind: :match, offset_days: 3, home: true, name: "vs Rivals")
		def event.total_score
			{ ours: { points: 60, team: "TC" }, opps: { points: 70, team: "Rivals" } }
		end

		html = render_inline(build_component(events: [ event ])).to_html
		assert_includes html, "bg-red-300"
	end

	test "match event renders with yellow class on draw" do
		event = make_event(kind: :match, offset_days: 3, home: true, name: "vs Rivals")
		def event.total_score
			{ ours: { points: 70, team: "TC" }, opps: { points: 70, team: "Rivals" } }
		end

		html = render_inline(build_component(events: [ event ])).to_html
		assert_includes html, "bg-yellow-300"
	end

	test "train event renders with blue class" do
		event = make_event(kind: :train, offset_days: 2)
		html  = render_inline(build_component(events: [ event ])).to_html
		assert_includes html, "bg-blue-300"
		assert_includes html, "hover:bg-blue-700"
	end

	test "rest event renders with gray class" do
		event = make_event(kind: :rest, offset_days: 4)
		html  = render_inline(build_component(events: [ event ])).to_html
		assert_includes html, "bg-gray-300"
		assert_includes html, "hover:bg-gray-700"
	end

	# ─── CSS presence (locks in EVENT_STYLES) ───────
	test "event styles compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		%w[
			bg-green-300 bg-red-300 bg-yellow-300 bg-blue-300 bg-gray-300
			hover:bg-green-700 hover:bg-red-700 hover:bg-yellow-700
			hover:bg-blue-700 hover:bg-gray-700
			bg-green-700 bg-red-700 bg-yellow-700 bg-blue-700 bg-gray-700
		].each do |cls|
			assert_includes css, cls, "Missing compiled class: #{cls} — run bin/rails tailwindcss:build"
		end
	end
end

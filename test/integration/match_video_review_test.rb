require "test_helper"

class MatchVideoReviewTest < ActionDispatch::IntegrationTest
	include Devise::Test::IntegrationHelpers
	# shared fixtures are out of sync with the schema: build the records here
	self.fixture_table_names = []

	setup do
		sport  = Sport.create!(name: "basketball")
		club   = Club.create!(name: "Test Club", nick: "TC", settings: { locale: "en" })
		season = Season.create!(start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 6, 30))
		court  = Location.create!(name: "Court")
		@team  = Team.create!(name: "U18", season:, sport:, club:, homecourt_id: court.id,
			category: Category.create!(age_group: "U18", sex: "male", min_years: 15, max_years: 17, rules: 0, sport:),
			division: Division.create!(name: "Regional", sport:))
		@coach    = new_user(:coach, "coach@test.example")
		@player   = new_user(:player, "player@test.example", number: 7)
		@teammate = new_user(:player, "mate@test.example", number: 9)
		@match    = Event.create!(team: @team, kind: :match, location: court, name: "Rivals", video_url: "https://youtu.be/dQw4w9WgXcQ",
			start_time: Time.utc(2026, 10, 10, 11), end_time: Time.utc(2026, 10, 10, 13))
	end

	test "coach links the match video and rejects other links" do
		sign_in @coach
		patch update_video_event_path(@match), params: { event: { video_url: "https://www.youtube.com/watch?v=aqz-KE-bpKQ" } }
		assert_redirected_to event_path(@match)
		assert_equal "aqz-KE-bpKQ", @match.reload.video_id

		patch update_video_event_path(@match), params: { event: { video_url: "https://vimeo.com/123456" } }
		assert_equal "aqz-KE-bpKQ", @match.reload.video_id
	end

	test "coach tags and deletes moments" do
		sign_in @coach
		get new_event_moment_path(@match)
		assert_response :success

		assert_difference("Moment.count") do
			post event_moments_path(@match), params: { moment: { time: "12:34", player_id: player_of(@player).id, kind: "good", note: "Great box out" } }
		end
		moment = Moment.last
		assert_redirected_to event_path(@match)
		assert_equal [ 754, player_of(@player) ], [ moment.second, moment.player ]

		get event_path(@match)
		assert_select "#video-review iframe[src*='youtube-nocookie.com/embed/dQw4w9WgXcQ']"
		assert_select "##{ActionView::RecordIdentifier.dom_id(moment)}", text: /Great box out/

		assert_difference("Moment.count", -1) { delete event_moment_path(@match, moment) }
	end

	test "players cannot tag moments nor change the video" do
		sign_in @player
		assert_no_difference("Moment.count") do
			post event_moments_path(@match), params: { moment: { time: "1:00", kind: "note", note: "Sneaky" } }
		end
		patch update_video_event_path(@match), params: { event: { video_url: "https://youtu.be/aqz-KE-bpKQ" } }
		assert_equal "dQw4w9WgXcQ", @match.reload.video_id
	end

	test "players only see team moments and their own feedback" do
		@match.moments.create!(time: "1:00", kind: :note, note: "Team: transition defence")
		@match.moments.create!(time: "2:00", kind: :good, note: "Mine: great box out", player: player_of(@player))
		@match.moments.create!(time: "3:00", kind: :improve, note: "Theirs: late rotation", player: player_of(@teammate))

		sign_in @player
		get event_path(@match)
		assert_response :success
		assert_select "#video-review li", 2
		assert_match "Team: transition defence", response.body
		assert_match "Mine: great box out", response.body
		assert_no_match "Theirs: late rotation", response.body
		assert_select "#video-review a.delete-btn", 0
	end

	private
		# user linked to a coach or a player of @team
		def new_user(role, email, number: nil)
			person = Person.create!(name: role.to_s.capitalize, surname: email.split("@").first, birthday: "2000-01-01", female: false, email:)
			user   = User.create!(email:, password: "secret123", role:, club: @team.club, person_id: person.id)
			if role == :coach
				coach = Coach.create!(club: @team.club, person_id: person.id)
				person.update!(coach_id: coach.id, user_id: user.id)
				@team.coaches << coach
			else
				player = Player.create!(club: @team.club, number:, person_id: person.id)
				person.update!(player_id: player.id, user_id: user.id)
				@team.players << player
			end
			user
		end

		def player_of(user)
			user.person.player
		end
end

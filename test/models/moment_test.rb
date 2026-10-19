require "test_helper"

class MomentTest < ActiveSupport::TestCase
	# shared fixtures are out of sync with the schema: use in-memory records
	self.fixture_table_names = []

	setup do
		@player = Player.new(id: 7, number: 7)
		team    = Team.new(name: "U18 male")
		team.players << @player
		@event  = Event.new(kind: :match, team:)
	end

	test "parses video positions" do
		{ "45" => 45, "12:34" => 754, "1:02:03" => 3723, " 0:07 " => 7 }.each do |t_string, second|
			assert_equal second, Moment.new(time: t_string).second, t_string
		end
	end

	test "formats video positions" do
		{ 45 => "0:45", 754 => "12:34", 3723 => "1:02:03" }.each do |second, t_string|
			assert_equal t_string, Moment.new(second:).time
		end
	end

	test "rejects malformed times" do
		[ "", "12:xx", "-5", "1:2:3:4", "1.5" ].each do |t_string|
			moment = new_moment(time: t_string)
			assert_not moment.valid?, t_string.inspect
			assert moment.errors.key?(:second)
		end
		I18n.with_locale(:en) do
			assert_includes new_moment(time: "12:xx").tap(&:validate).errors.full_messages, "Time must look like 12:34"
		end
	end

	test "requires a short note" do
		assert_not new_moment(note: "").valid?
		assert_not new_moment(note: "x" * 201).valid?
		assert new_moment(note: "x" * 200).valid?
	end

	test "can be tagged to the whole team or to one of its players" do
		assert new_moment(player: nil).valid?
		assert new_moment(player: @player).valid?
		outsider = new_moment(player: Player.new(id: 99, number: 99))
		assert_not outsider.valid?
		assert outsider.errors.key?(:player)
	end

	private
		def new_moment(time: "12:34", note: "Great box out", player: nil)
			Moment.new(event: @event, time:, note:, player:, kind: :good)
		end
end

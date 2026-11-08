require "test_helper"

class TopbarComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# ─── testable subclass ──────────────────────────────────────────
	# image_tag is overridden to a stable marker so tests don't touch
	# ActiveStorage. attachment_readable? is overridable per instance
	# so we can exercise both the "logo present" and "logo fallback"
	# branches without attaching a real blob.
	class TestableTopbar < TopbarComponent
		private
			# image_tag override stays — keeps tests off ActiveStorage
			def image_tag(source, **opts)
				tag.img(src: source.to_s, class: opts[:class])
			end
	end

	# ─── fakes ──────────────────────────────────────────────────────
	FakePerson = Struct.new(:nick, :name)

	FakeTeam = Struct.new(:id, :name, :club, :season, keyword_init: true) do
		def club_id;   club.id;   end
		def to_s;      name;      end
	end

	def fake_team(id:, club:, season: nil, name: "Team #{id}")
		FakeTeam.new(id: id, name: name, club: club, season: season || seasons(:current))
	end

	def fake_user(person: FakePerson.new("alice", "Alice"),
								teams: [],
								admin: false, manager: false, secretary: false,
								coach: false, athlete: false)
		u = Object.new
		u.define_singleton_method(:person)        { person }
		u.define_singleton_method(:teams)         { teams }
		u.define_singleton_method(:admin?)        { admin }
		u.define_singleton_method(:is_manager?)   { |_club| manager }
		u.define_singleton_method(:is_secretary?) { |_club| secretary }
		u.define_singleton_method(:is_coach?)     { coach }
		u.define_singleton_method(:is_athlete?)   { athlete }
		u
	end

	# ─── render helper ──────────────────────────────────────────────
	# Season.latest is stubbed to the fixture so team_menu's
	# current-season filter is deterministic.
	def render_topbar(user:, club: nil, home: "/home", logout: "/sign_out",
										registrations_url: nil, logo_readable: nil)
		html = nil
		with_stub(Server, :server_logo, "stub-logo.png") do
			with_stub(Server, :server_name, "Stub Server") do
				with_stub(Season, :latest, seasons(:current)) do
					component = TestableTopbar.new(
						user: user, club: club, home: home, logout: logout,
						registrations_url: registrations_url
					)
					component.force_logo_readable = logo_readable unless logo_readable.nil?
					html = render_inline(component).to_html
				end
			end
		end
		html
	end

	# ─── wrapper structure ──────────────────────────────────────────
	test "wraps content in a nav element" do
		nav = parsed(render_topbar(user: fake_user)).css("nav").first
		refute_nil nav
		assert_includes nav["class"], "max-w-7xl"
	end

	test "inner div uses flex layout with justify-between and h-12" do
		nav = parsed(render_topbar(user: fake_user)).css("nav").first
		div = nav.css("> div").first
		refute_nil div
		assert_includes div["class"], "flex"
		assert_includes div["class"], "justify-between"
		assert_includes div["class"], "h-12"
	end

	# ─── logo ───────────────────────────────────────────────────────
	test "logo links to root with turbo_action replace" do
		link = parsed(render_topbar(user: fake_user)).css("a[href='/']").first
		refute_nil link
		assert_equal "replace", link["data-turbo-action"]
	end

	test "logo renders two responsive image variants" do
		imgs = parsed(render_topbar(user: fake_user)).css("a[href='/'] img")
		assert_equal 2, imgs.size
		classes = imgs.map { |i| i["class"] }
		assert_includes classes, "block lg:hidden h-8 w-auto"
		assert_includes classes, "hidden lg:block h-8 w-auto"
	end

	test "anonymous user sees the server name" do
		assert_includes render_topbar(user: nil), "Stub Server"
	end

	# ─── Bug D: logo fallback ───────────────────────────────────────
	test "non-admin club member sees the club nick" do
		club = clubs(:north)
		html = render_topbar(user: fake_user(teams: [], coach: true), club: club)
		assert_includes html, club.nick
		refute_includes html, "Stub Server"
	end

	test "admin sees the server name regardless of club" do
		club = clubs(:north)
		html = render_topbar(user: fake_user(teams: [], admin: true), club: club)
		assert_includes html, "Stub Server"
		refute_includes html, club.nick
	end

	# ─── anonymous ──────────────────────────────────────────────────
	test "anonymous user sees a sign-in link" do
		assert parsed(render_topbar(user: nil)).css("a[href='/users/sign_in']").any?
	end

	test "anonymous user has no navigation block" do
		html = render_topbar(user: nil)
		assert_equal 0, parsed(html).css("div[aria-label='Navigation']").size
	end

	test "account wrapper always renders" do
		assert parsed(render_topbar(user: nil)).css("div[aria-label='Account']").any?
		assert parsed(render_topbar(user: fake_user)).css("div[aria-label='Account']").any?
	end

	# ─── role-based nav tabs ────────────────────────────────────────
	test "coach sees the drills link" do
		user = fake_user(teams: [], coach: true)
		assert parsed(render_topbar(user: user, club: clubs(:north)))
			.css("a[href='/drills']").any?
	end

	test "secretary sees membership, slot, and location links" do
		user = fake_user(teams: [], secretary: true)
		html = render_topbar(user: user, club: clubs(:north))

		assert parsed(html).css("a[href*='memberships?kind=athlete']").any?
		assert parsed(html).css("a[href*='memberships?kind=coach']").any?
		assert parsed(html).css("a[href*='/slots']").any?
		assert parsed(html).css("a[href*='/locations']").any?
	end

	test "admin manager sees the club link" do
		club = clubs(:north)
		user = fake_user(teams: [], manager: true, admin: true)
		assert parsed(render_topbar(user: user, club: club))
			.css("a[href='/clubs/#{club.id}']").any?
	end

	test "non-admin manager sees the log link" do
		club = clubs(:north)
		user = fake_user(teams: [], manager: true, admin: false)
		assert parsed(render_topbar(user: user, club: club))
			.css("a[href='/server/log']").any?
	end

	# ─── Bug C: team menu ──────────────────────────────────────────
	test "user with no teams has no Teams menu" do
		user = fake_user(teams: [], coach: true)
		refute parsed(render_topbar(user: user, club: nil)).css("a[href*='/teams']").any?
	end

	test "user with teams in one club gets a flat Teams dropdown" do
		club = clubs(:test_club)
		team = fake_team(id: 42, club: club)
		user = fake_user(teams: [ team ], coach: true)

		html = render_topbar(user: user, club: nil)
		assert parsed(html).css("a[href='/clubs/#{club.id}/teams/42']").any?,
			"expected a direct link to the user's team"
		assert parsed(html).css("a[href='/clubs/#{club.id}/teams']").any?,
			"expected an 'All teams' link for the club"
	end

	test "user with teams in two clubs gets a nested Teams dropdown" do
		north = clubs(:north)
		test_club = clubs(:test_club)
		north_team = fake_team(id: 1, club: north, name: "Northside U18")
		test_team  = fake_team(id: 2, club: test_club, name: "Test Senior")
		user = fake_user(teams: [ north_team, test_team ], coach: true)

		html = render_topbar(user: user, club: nil)
		assert parsed(html).css("a[href='/clubs/#{north.id}/teams/1']").any?
		assert parsed(html).css("a[href='/clubs/#{test_club.id}/teams/2']").any?
		assert parsed(html).css("a[href='/clubs/#{north.id}/teams']").any?
		assert parsed(html).css("a[href='/clubs/#{test_club.id}/teams']").any?
	end

	test "in club context, Teams menu restricts to that club" do
		north = clubs(:north)
		test_club = clubs(:test_club)
		north_team = fake_team(id: 1, club: north)
		test_team  = fake_team(id: 2, club: test_club)
		user = fake_user(teams: [ north_team, test_team ], coach: true)

		html = render_topbar(user: user, club: north)
		assert parsed(html).css("a[href='/clubs/#{north.id}/teams/1']").any?
		refute parsed(html).css("a[href='/clubs/#{test_club.id}/teams/2']").any?,
			"other clubs' teams must not leak into a club-scoped menu"
	end

	test "teams from a non-current season are excluded" do
		club = clubs(:north)
		old_season = Season.create!(
			start_date: 5.years.ago.beginning_of_year,
			end_date:   4.years.ago.end_of_year
		)
		old_team = fake_team(id: 99, club: club, season: old_season)
		user = fake_user(teams: [ old_team ], coach: true)

		html = render_topbar(user: user, club: nil)
		refute parsed(html).css("a[href*='/teams/99']").any?,
			"stale-season teams should not appear in the top bar"
	end

	# ─── registrations link ─────────────────────────────────────────
	test "registrations link renders when a URL is passed" do
		user = fake_user(teams: [], coach: true)
		html = render_topbar(user: user, club: clubs(:north),
												registrations_url: "/registrations")
		assert parsed(html).css("a[href='/registrations']").any?
	end

	test "registrations link is absent when no URL is passed" do
		user = fake_user(teams: [], coach: true)
		html = render_topbar(user: user, club: clubs(:north))
		refute parsed(html).css("a[href='/registrations']").any?
	end

	# ─── account action ─────────────────────────────────────────────
	test "signed-in user gets a profile dropdown, not a sign-in link" do
		user = fake_user(teams: [], coach: true)
		html = render_topbar(user: user, club: clubs(:north))

		refute parsed(html).css("a[href='/users/sign_in']").any?
		assert parsed(html).css("div[aria-label='Account']").any?
	end

	# ─── Bug A + B: hamburger ──────────────────────────────────────
	test "hamburger renders when nav tabs are present" do
		user = fake_user(teams: [], coach: true)
		html = render_topbar(user: user, club: clubs(:north))
		assert parsed(html).css("div[aria-label='Mobile menu']").any?
	end

	test "hamburger is hidden at the same breakpoint desktop nav is shown" do
		html = render_topbar(user: fake_user(teams: [], coach: true), club: clubs(:north))

		hamburger = parsed(html).css("div[aria-label='Mobile menu']").first
		nav       = parsed(html).css("div[aria-label='Navigation']").first

		refute_nil hamburger
		refute_nil nav

		# Extract the breakpoint from nav (e.g. "hidden md:block" → "md")
		nav_bp = nav["class"][/hidden (\w+):block/, 1]
		refute_nil nav_bp, "nav should use `hidden <bp>:block` so it hides below #{nav_bp}"

		assert_includes hamburger["class"], "#{nav_bp}:hidden",
			"hamburger must hide at #{nav_bp}, same breakpoint nav appears at (found: #{hamburger['class']})"
	end

	test "hamburger includes the account action for signed-in users" do
		user = fake_user(teams: [], coach: true)
		hamburger = parsed(render_topbar(user: user, club: clubs(:north)))
			.css("div[aria-label='Mobile menu']").first

		refute_nil hamburger
		# before Bug A fix: the hamburger only clones @nav_tabs, so /sign_out
		# (which lives on @acc_acts) never appeared → mobile users had no way
		# to sign out
		assert_match %r{/sign_out}, hamburger.to_html,
			"signed-in users must be able to sign out from the mobile menu"
	end

	test "anonymous user gets a hamburger containing a sign-in link" do
		html = render_topbar(user: nil)

		hamburger = parsed(html).css("div[aria-label='Mobile menu']").first
		refute_nil hamburger,
			"anonymous users must have a mobile path to sign in"

		assert_match %r{/users/sign_in}, hamburger.to_html,
			"the hamburger must include the sign-in link (account block is hidden on mobile)"
	end

	# ─── alignment: right-side triggers open leftward ─────────────────
	test "profile dropdown is right-aligned (bottom-end)" do
			html = render_topbar(user: fake_user(teams: [], coach: true), club: clubs(:north))
			account = parsed(html).css("div[aria-label='Account']").first
			refute_nil account
			menu = account.at_css("[data-dropdown-target='menu']")
			refute_nil menu
			assert_includes menu["class"], "right-0",
					"profile dropdown must open right-to-left (got: #{menu['class']})"
			refute_includes menu["class"], "left-0"
	end

	test "hamburger menu is right-aligned (bottom-end)" do
			html = render_topbar(user: fake_user(teams: [], coach: true), club: clubs(:north))
			mobile = parsed(html).css("div[aria-label='Mobile menu']").first
			refute_nil mobile
			menu = mobile.at_css("[data-dropdown-target='menu']")
			refute_nil menu
			assert_includes menu["class"], "right-0",
					"hamburger must open right-to-left on narrow viewports"
			refute_includes menu["class"], "left-0"
	end

	test "hamburger sub-menus inherit left-start (right-full) from the flipped parent" do
			club = clubs(:north)
			team = fake_team(id: 42, club: club)
			user = fake_user(teams: [ team ], coach: true)

			html = render_topbar(user: user, club: nil)
			mobile = parsed(html).css("div[aria-label='Mobile menu']").first
			refute_nil mobile

			sub_menus = mobile.css("[data-dropdown-target='menu'] [data-dropdown-target='menu']")
			refute_empty sub_menus, "hamburger should contain at least one nested sub-menu (Equipos)"

			sub_menus.each do |m|
					assert_includes m["class"], "right-full",
							"hamburger sub-menus must open leftward when the parent is flipped (got: #{m['class']})"
			end
	end

	# ─── flipped link alignment ───────────────────────────────────────
	test "leaf links right-align inside right-aligned menus" do
			html = render_topbar(user: fake_user(teams: [], coach: true), club: clubs(:north))
			mobile = parsed(html).css("div[aria-label='Mobile menu']").first
			refute_nil mobile
			# Direct leaf items of the hamburger menu (drills, etc.)
			leaves = mobile.css("[data-dropdown-target='menu'] > ul > li > a")
			refute_empty leaves
			leaves.each do |a|
					assert_includes a["class"], "justify-end",
							"flipped menu leaf links must right-align (got: #{a['class']})"
			end
	end

	# ─── hamburger trigger has hover feedback ─────────────────────────
	test "hamburger trigger carries hover feedback" do
			html = render_topbar(user: fake_user(teams: [], coach: true), club: clubs(:north))
			mobile = parsed(html).css("div[aria-label='Mobile menu']").first
			trigger = mobile.at_css("[data-dropdown-target='trigger']")
			refute_nil trigger
			# The CSS override [data-dropdown-target="trigger"]:hover covers this,
			# but MENU_CLS also has hover:* explicitly — either is fine, but the
			# trigger must have *some* hover class in its class attribute.
			assert_includes trigger["class"], "hover:bg-blue-700",
					"hamburger trigger must carry hover styling (got: #{trigger['class']})"
	end

	# ─── dead-code regression guard ──────────────────────────────────
	test "no class contains a stray quote character" do
			html = render_topbar(user: fake_user(teams: [], coach: true), club: clubs(:north))
			# Regression: SRV_CLS had `items-center"` which produced an invalid token
			parsed(html).css("[class]").each do |el|
					refute_includes el["class"], '"',
							"invalid class attribute on #{el.name} — a Ruby %w[] literal likely contains a stray quote"
			end
	end

	# ─── CSS presence ───────────────────────────────────────────────
	test "layout classes compile into the Tailwind output" do
		css = File.read(Rails.root.join("app/assets/builds/tailwind.css")).gsub(/\\/, "")
		required = %w[
				max-w-7xl mx-auto px-2 sm:px-6 lg:px-8
				relative flex items-center justify-between h-12
				flex-shrink-0 inline-flex font-semibold
				block lg:hidden h-8 w-auto hidden lg:block
				hidden md:block md:hidden
				hover:bg-blue-700 hover:text-white
				focus:bg-blue-700 focus:text-white
				focus:ring-2 focus:ring-gray-200
				whitespace-nowrap rounded-md px-2 py-2
				justify-end right-0 mt-2 right-full mr-1
		]
		missing = required.reject { |cls| css.include?(cls) }
		assert_empty missing,
				"Missing compiled classes: #{missing.join(', ')}. " \
				"Fix: verify @source in app/assets/tailwind/application.css covers " \
				"app/components/**/*.rb, then run `bin/rails tailwindcss:build`."
	end
end

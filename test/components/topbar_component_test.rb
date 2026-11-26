# frozen_string_literal: true

require "test_helper"

class TopbarComponentTest < ActiveSupport::TestCase
	include ViewComponent::TestHelpers

	# ─── testable subclass ──────────────────────────────────────────
	class TestableTopbar < TopbarComponent
		private
			def image_tag(source, **opts)
				tag.img(src: source.to_s, class: opts[:class])
			end
	end

	# ─── fakes ──────────────────────────────────────────────────────
	FakePerson = Struct.new(:nick, :name)

	FakeTeam = Struct.new(:id, :name, :club, :season, keyword_init: true) do
		def club_id; club.id; end
		def to_s;    name;    end
	end

	def fake_team(id:, club:, season: nil, name: "Team #{id}")
		FakeTeam.new(id: id, name: name, club: club, season: season || seasons(:current))
	end

	def fake_user(id: 1,
								person: FakePerson.new("alice", "Alice"),
								email: "alice@example.com",
								picture: { symbol: :user },
								teams: [],
								admin: false, manager: false, secretary: false,
								coach: false, athlete: false)
		u = Object.new
		u.define_singleton_method(:id)            { id }
		u.define_singleton_method(:person)        { person }
		u.define_singleton_method(:email)         { email }
		u.define_singleton_method(:picture)       { picture }
		u.define_singleton_method(:teams)         { teams }
		u.define_singleton_method(:admin?)        { admin }
		u.define_singleton_method(:is_manager?)   { |_club = nil| manager }
		u.define_singleton_method(:is_secretary?) { |_club = nil| secretary }
		u.define_singleton_method(:is_coach?)     { coach }
		u.define_singleton_method(:is_athlete?)   { athlete }
		u
	end

	# Stubs policy checks cleanly without coupling TopbarComponentTest to Pundit internals
	ALL_POLICIES = {
		MembershipPolicy   => :index?,
		RegistrationPolicy => :index?,
		SlotPolicy         => :index?,
		LocationPolicy     => :index?,
		EventPolicy        => :index?,
		ServerPolicy       => :log?
	}.freeze

	def with_policies(allowed = {})
		originals = {}

		ALL_POLICIES.each do |policy_class, action|
			next unless defined?(policy_class)

			allow = allowed.fetch(policy_class, false)
			originals[policy_class] = policy_class.instance_method(action) if policy_class.method_defined?(action)
			policy_class.define_method(action) { allow }
		end

		yield
	ensure
		originals.each do |policy_class, method_obj|
			policy_class.define_method(ALL_POLICIES.fetch(policy_class), method_obj)
		end
	end

	# ─── render helper ──────────────────────────────────────────────
	def render_topbar(user:, club: nil, clubs: [], home: "/home", logout: "/sign_out",
										registrations_url: nil, policies: {}, controller_club: :unset)
		html = nil

		orig_dropdown_img = DropdownComponent.instance_method(:image_tag) rescue nil
		DropdownComponent.define_method(:image_tag) do |source, **opts|
			tag.img(src: source.to_s, class: opts[:class])
		end

		club_stubs = ([ club ] + Array(clubs)).compact.uniq
		orig_logos = {}
		club_stubs.each do |c|
			next unless c.is_a?(Club)

			orig_logos[c] = c.method(:logo)
			c.define_singleton_method(:logo) { "club_#{c.id}.svg" }
		end

		with_stub(Server, :server_logo, "mudclub.svg") do
			with_stub(Server, :server_name, "Stub Server") do
				with_stub(Season, :latest, seasons(:current)) do
					with_policies(policies) do
						component = TestableTopbar.new(
							user: user, club: club, clubs: clubs, home: home, logout: logout,
							registrations_url: registrations_url
						)
						if controller_club != :unset
							vc_test_controller.instance_variable_set(:@club, controller_club)
						end
						html = render_inline(component).to_html
					end
				end
			end
		end

		html
	ensure
		if orig_dropdown_img
			DropdownComponent.define_method(:image_tag, orig_dropdown_img)
		elsif DropdownComponent.method_defined?(:image_tag, false)
			DropdownComponent.remove_method(:image_tag)
		end

		orig_logos&.each do |c, orig|
			c.define_singleton_method(:logo, orig)
		end
	end

	# ─── wrapper structure ──────────────────────────────────────────
	test "wraps content in a nav element" do
		nav = parsed(render_topbar(user: fake_user)).css("nav").first
		refute_nil nav
		assert_includes nav["class"], "max-w-7xl"
	end

	test "inner div uses flex layout with justify-between and h-14" do
		nav = parsed(render_topbar(user: fake_user)).css("nav").first
		div = nav.css("> div").first
		refute_nil div
		assert_includes div["class"], "flex"
		assert_includes div["class"], "justify-between"
		assert_includes div["class"], "h-14"
	end

	# ─── logo & context switcher ────────────────────────────────────
	test "logo links to root with club_id=none when no club is active" do
		link = parsed(render_topbar(user: fake_user)).css("a[href='/?club_id=none']").first
		refute_nil link
		assert_equal "replace", link["data-turbo-action"]
	end

	test "logo renders brand image with IMG_SIZE class" do
		imgs = parsed(render_topbar(user: fake_user)).css("a[href='/?club_id=none'] img")
		assert_equal 1, imgs.size
		assert_equal "h-8 w-auto", imgs.first["class"]
	end

	test "non-Club object passed as club falls back to server branding" do
		html = render_topbar(user: fake_user, club: :invalid_club)
		assert_includes html, "Stub Server"
		assert parsed(html).css("a[href='/?club_id=none']").any?
	end

	test "before_render re-syncs with controller @club instance variable" do
		north = clubs(:north)
		test_club = clubs(:test_club)

		html = render_topbar(
			user: fake_user,
			club: north,
			clubs: [ north, test_club ],
			controller_club: test_club
		)
		assert_includes html, test_club.nick
	end

	test "anonymous user sees the server name" do
		assert_includes render_topbar(user: nil), "Stub Server"
	end

	test "non-admin single-club member sees plain club link without switcher" do
		club = clubs(:north)
		html = render_topbar(user: fake_user(teams: [], coach: true), club: club, clubs: [ club ])
		doc = parsed(html)

		assert_includes html, club.nick
		refute_includes html, "Stub Server"
		assert_nil doc.at_css("#context_switcher-btn")
		assert doc.css("a[href='/clubs/#{club.id}']").any?
	end

	test "multi-club member gets a context switcher excluding the active club" do
		north = clubs(:north)
		test_club = clubs(:test_club)
		user = fake_user(coach: true)

		html = render_topbar(user: user, club: north, clubs: [ north, test_club ])
		doc = parsed(html)

		trigger = doc.at_css("#context_switcher-btn")
		refute_nil trigger
		assert_includes trigger.text, north.nick

		menu = doc.at_css("#context_switcher")
		assert menu.css("a[href='/clubs/#{test_club.id}']").any?
		assert_empty menu.css("a[href='/clubs/#{north.id}']"),
			"active club must be omitted from the switcher options"
	end

	test "admin inside a club sees club nick on trigger and Server link in switcher" do
		north = clubs(:north)
		user = fake_user(admin: true)

		html = render_topbar(user: user, club: north, clubs: [ north ])
		doc = parsed(html)

		trigger = doc.at_css("#context_switcher-btn")
		refute_nil trigger
		assert_includes trigger.text, north.nick

		menu = doc.at_css("#context_switcher")
		assert menu.css("a[href='/?club_id=none']").any?,
			"admin in a club must have a switcher option back to Server"
	end

	test "admin outside a club gets switcher with clubs but no redundant Server option" do
		north = clubs(:north)
		user = fake_user(admin: true)

		html = render_topbar(user: user, club: nil, clubs: [ north ])
		doc = parsed(html)

		menu = doc.at_css("#context_switcher")
		refute_nil menu
		assert menu.css("a[href='/clubs/#{north.id}']").any?
		assert_empty menu.css("a[href='/?club_id=none']"),
			"admin already at server root should not see Server inside switcher"
	end

	test "admin with zero clubs gets plain server link instead of empty switcher" do
		html = render_topbar(user: fake_user(admin: true), club: nil, clubs: [])
		doc = parsed(html)

		assert_nil doc.at_css("#context_switcher-btn")
		assert doc.css("a[href='/?club_id=none']").any?
	end

	# ─── anonymous ──────────────────────────────────────────────────
	test "anonymous user sees a sign-in link" do
		assert parsed(render_topbar(user: nil)).css("a[href='/users/sign_in']").any?
	end

	test "anonymous user without registrations_url has no navigation block" do
		html = render_topbar(user: nil, registrations_url: nil)
		assert_equal 0, parsed(html).css("div[aria-label='Navigation']").size
	end

	test "anonymous user with registrations_url gets navigation block with registrations link" do
		html = render_topbar(user: nil, registrations_url: "/registrations")
		nav = parsed(html).at_css("div[aria-label='Navigation']")
		refute_nil nav
		assert nav.css("a[href='/registrations']").any?
	end

	test "account wrapper always renders" do
		assert parsed(render_topbar(user: nil)).css("div[aria-label='Account']").any?
		assert parsed(render_topbar(user: fake_user)).css("div[aria-label='Account']").any?
	end

	# ─── role-based nav tabs & club management ──────────────────────
	test "coach sees the drills link in desktop navigation" do
		user = fake_user(teams: [], coach: true)
		nav = parsed(render_topbar(user: user, club: clubs(:north))).at_css("div[aria-label='Navigation']")
		refute_nil nav
		assert nav.css("a[href='/drills']").any?
	end

	test "club management menu renders permitted sections" do
		club = clubs(:north)
		user = fake_user(secretary: true, admin: false)
		policies = {
			MembershipPolicy   => true,
			RegistrationPolicy => true,
			SlotPolicy         => true,
			LocationPolicy     => true,
			EventPolicy        => true,
			ServerPolicy       => true
		}

		nav = parsed(render_topbar(user: user, club: club, policies: policies)).at_css("div[aria-label='Navigation']")
		refute_nil nav
		assert nav.css("a[href*='/members?kind=athlete']").any?
		assert nav.css("a[href*='/members?kind=coach']").any?
		assert nav.css("a[href='/clubs/#{club.id}/registrations']").any?
		assert nav.css("a[href='/clubs/#{club.id}/slots']").any?
		assert nav.css("a[href='/clubs/#{club.id}/locations']").any?
		assert nav.css("a[href='/clubs/#{club.id}/events']").any?
		assert nav.css("a[href='/server/log']").any?
	end

	test "admin does not see server log inside club management menu even if ServerPolicy allows" do
		club = clubs(:north)
		user = fake_user(admin: true)
		policies = { MembershipPolicy => true, ServerPolicy => true }
		nav = parsed(render_topbar(user: user, club: club, policies: policies)).at_css("div[aria-label='Navigation']")
		refute_nil nav
		assert_empty nav.css("a[href='/server/log']")
	end

		test "admin belonging to a single club always sees the club menu even outside club context" do
		club = clubs(:north)
		user = fake_user(admin: true)
		policies = { MembershipPolicy => true }

		nav = parsed(render_topbar(user: user, club: nil, clubs: [ club ], policies: policies))
			.at_css("div[aria-label='Navigation']")
		refute_nil nav
		assert_not_nil nav.at_css("#club_mgmt-btn"),
			"single-club admin must always see the club management menu"
		assert nav.css("a[href='/clubs/#{club.id}/members?kind=athlete']").any?
	end

	test "admin belonging to multiple clubs does not see club menu when outside club context" do
		north = clubs(:north)
		test_club = clubs(:test_club)
		user = fake_user(admin: true)
		policies = { MembershipPolicy => true }

		html = render_topbar(user: user, club: nil, clubs: [ north, test_club ], policies: policies)
		assert_nil parsed(html).at_css("#club_mgmt-btn"),
			"multi-club admin at server root has no single club to scope the club menu to"
	end

	# ─── team menu ──────────────────────────────────────────────────
	test "regular user with no teams has no Teams menu" do
		user = fake_user(teams: [], coach: true)
		refute parsed(render_topbar(user: user, club: clubs(:north))).css("a[href*='/teams']").any?
	end

	test "secretary or manager with no teams still gets Teams menu with All teams link" do
		club = clubs(:north)
		secretary = fake_user(teams: [], secretary: true)
		nav = parsed(render_topbar(user: secretary, club: club)).at_css("div[aria-label='Navigation']")
		refute_nil nav
		assert nav.css("a[href='/clubs/#{club.id}/teams']").any?
	end

	test "user with teams in one club gets a flat Teams dropdown" do
		club = clubs(:test_club)
		team = fake_team(id: 42, club: club)
		user = fake_user(teams: [ team ], coach: true)
		nav = parsed(render_topbar(user: user, club: nil)).at_css("div[aria-label='Navigation']")
		assert nav.css("a[href='/clubs/#{club.id}/teams/42']").any?,
		"expected a direct link to the user's team"
		assert nav.css("a[href='/clubs/#{club.id}/teams']").any?,
		"expected an 'All teams' link for the club"
	end

	test "user with teams in two clubs gets a nested Teams dropdown" do
		north = clubs(:north)
		test_club = clubs(:test_club)
		north_team = fake_team(id: 1, club: north, name: "Northside U18")
		test_team  = fake_team(id: 2, club: test_club, name: "Test Senior")
		user = fake_user(teams: [ north_team, test_team ], coach: true)
		nav = parsed(render_topbar(user: user, club: nil)).at_css("div[aria-label='Navigation']")
		assert nav.css("a[href='/clubs/#{north.id}/teams/1']").any?
		assert nav.css("a[href='/clubs/#{test_club.id}/teams/2']").any?
		assert nav.css("a[href='/clubs/#{north.id}/teams']").any?
		assert nav.css("a[href='/clubs/#{test_club.id}/teams']").any?
	end

	test "in club context, Teams menu restricts to that club" do
		north = clubs(:north)
		test_club = clubs(:test_club)
		north_team = fake_team(id: 1, club: north)
		test_team  = fake_team(id: 2, club: test_club)
		user = fake_user(teams: [ north_team, test_team ], coach: true)
		nav = parsed(render_topbar(user: user, club: north)).at_css("div[aria-label='Navigation']")
		assert nav.css("a[href='/clubs/#{north.id}/teams/1']").any?
		assert_empty nav.css("a[href='/clubs/#{test_club.id}/teams/2']"),
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

	# ─── account action & profile fallbacks ─────────────────────────
	test "signed-in user gets profile dropdown with delete sign-out link" do
		user = fake_user(teams: [], coach: true)
		account = parsed(render_topbar(user: user, club: clubs(:north))).at_css("div[aria-label='Account']")
		assert_empty account.css("a[href='/users/sign_in']")
		sign_out = account.at_css("a[href='/sign_out']")
		refute_nil sign_out
		assert_equal "delete", sign_out["data-turbo-method"]
	end

	test "profile label falls back from nick to name to email" do
		no_nick = fake_user(person: FakePerson.new("", "Alice Smith"), email: "alice@example.com")
		account = parsed(render_topbar(user: no_nick)).at_css("div[aria-label='Account']")
		assert_includes account.text, "Alice Smith"
		no_person = fake_user(person: nil, email: "fallback@example.com")
		account2 = parsed(render_topbar(user: no_person)).at_css("div[aria-label='Account']")
		assert_includes account2.text, "fallback@example.com"
	end

	test "profile renders image avatar when picture is a URL/path instead of symbol" do
		user = fake_user(picture: "/avatars/alice.png")
		account = parsed(render_topbar(user: user)).at_css("div[aria-label='Account']")
		img = account.at_css("img[src='/avatars/alice.png']")
		refute_nil img
		assert_includes img["class"], "rounded-full"
	end

	test "registrations link renders inside profile dropdown when URL is passed" do
		user = fake_user(teams: [], coach: true)
		account = parsed(render_topbar(user: user, club: clubs(:north), registrations_url: "/registrations"))
										.at_css("div[aria-label='Account']")
		assert account.css("a[href='/registrations']").any?
	end

	test "registrations link is absent when no URL is passed" do
		user = fake_user(teams: [], coach: true)
		html = render_topbar(user: user, club: clubs(:north))
		refute parsed(html).css("a[href='/registrations']").any?
	end

	# ─── hamburger ──────────────────────────────────────────────────
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
		nav_bp = nav["class"][/hidden (\w+):block/, 1]
		refute_nil nav_bp, "nav should use hidden :block so it hides below #{nav_bp}"
		assert_includes hamburger["class"], "#{nav_bp}:hidden",
		"hamburger must hide at #{nav_bp}, same breakpoint nav appears at (found: #{hamburger['class']})"
	end

	test "hamburger includes the account action for signed-in users" do
		user = fake_user(teams: [], coach: true)
		hamburger = parsed(render_topbar(user: user, club: clubs(:north)))
		.css("div[aria-label='Mobile menu']").first
		refute_nil hamburger
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
		refute_empty sub_menus, "hamburger should contain at least one nested sub-menu (Teams)"
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
		assert_includes trigger["class"], "hover:bg-blue-700",
		"hamburger trigger must carry hover styling (got: #{trigger['class']})"
	end

	# ─── dead-code regression guard ──────────────────────────────────
	test "no class contains a stray quote character" do
		html = render_topbar(user: fake_user(teams: [], coach: true), club: clubs(:north))
		parsed(html).css("[class]").each do |el|
			refute_includes el["class"], '"',
			"invalid class attribute on #{el.name} — a Ruby %w[] literal likely contains a stray quote"
		end
	end

	# ─── CSS presence ───────────────────────────────────────────────
	test "layout classes compile into the Tailwind output" do
		css_path = Rails.root.join("app/assets/builds/tailwind.css")
		skip "tailwind.css has not been built yet" unless File.exist?(css_path)
		css = File.read(css_path).delete(92.chr)
		required = %w[
		max-w-7xl mx-auto px-2 sm:px-6 lg:px-8
		relative flex items-center justify-between h-14
		flex-shrink-0 inline-flex font-semibold
		h-8 w-auto
		hidden md:block md:hidden
		hover:bg-blue-700 hover:text-white
		focus:bg-blue-700 focus:text-white
		focus:ring-2 focus:ring-gray-200
		whitespace-nowrap rounded-md px-2 py-2
		justify-end right-0 mt-2 right-full mr-1
		]
		missing = required.reject { |cls| css.include?(cls) }
		assert_empty missing,
		"Missing compiled classes: #{missing.join(', ')}. "
	end
end

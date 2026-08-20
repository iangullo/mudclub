class CreateAssignments < ActiveRecord::Migration[8.0]
  def up
    create_table :assignments, id: :uuid do |t|
      t.references :membership, type: :uuid, null: false, foreign_key: true
      t.references :team, foreign_key: true
      t.integer :kind,   null: false
      t.integer :status, null: false, default: 0
      t.jsonb :settings, default: {}
      t.date :starts_on, null: false
      t.date :ends_on
      t.timestamps
    end

    # Club‑level assignments (from User records)
    infer_club_assignments

    # Team‑level assignments (coaches & athletes)
    infer_team_assignments
  end

  def down
    drop_table :assignments
  end

  private

  # ---- Club assignments ----
  def infer_club_assignments
    User.real.each do |user|
      next unless user.club_id

      kind =
        case user.role.to_sym
        when :secretary then :secretary
        when :manager   then :club_manager
        when :admin     then user.is_coach? ? :club_manager : nil
        else nil
        end
      next unless kind

      assignment_kind = Catalog::AssignmentKinds.fetch(kind)
      membership = user.person.memberships
                         .current
                         .for_club(user.club_id)
                         .of_kind(assignment_kind[:membership])
                         .first
      next unless membership

      create_club_assignment(membership, assignment_kind.id, membership.joined_on)
    end
  end

  # ---- Team assignments (coaches & athletes) ----
  def infer_team_assignments
    # --- Coaches ---
    Coach.real.find_each do |coach|
      coach.teams.joins(:season).order("seasons.start_date ASC").each do |team|
        # Determine if head or assistant (first in team.coaches order)
        coach_list = team.coaches.order(:id)
        position = coach_list.index(coach)
        kind = position == 0 ? :head_coach : :assistant_coach
        assignment_kind = Catalog::AssignmentKinds.fetch(kind)

        membership = find_or_create_membership(coach, team, :coach)
        next unless membership

        create_team_assignment(membership, team, assignment_kind.id)
      end
    end

    # --- Athletes ---
    # Build a set of all (player_id, team_id) pairs (current + historical)
    player_team_pairs = Set.new

    # Current
    Player.joins(:teams).pluck("players.id", "teams.id").each do |p_id, t_id|
      player_team_pairs.add([ p_id, t_id ])
    end

    # Historical (from events_players)
    Event.joins(:events_players)
         .where.not(team_id: nil)
         .pluck("events_players.player_id", :team_id)
         .each do |p_id, t_id|
      player_team_pairs.add([ p_id, t_id ])
    end

    athlete_kind = Catalog::AssignmentKinds.fetch(:athlete)

    player_team_pairs.each do |player_id, team_id|
      player = Player.find_by(id: player_id)
      next unless player

      team = Team.find_by(id: team_id)
      next unless team&.season

      membership = find_or_create_membership(player, team, :athlete)
      next unless membership

      create_team_assignment(membership, team, athlete_kind.id, player.number)
    end

    # --- SAFETY NET: catch any remaining pairs that still lack an assignment ---
    say_with_time "Catching missing athlete assignments" do
      catch_missing_athlete_assignments
    end
  end

  # ---- Shared helpers ----
  def find_or_create_membership(member, team, kind)
    person = member.person
    club = team.club

    # 1. Find overlapping or contiguous membership
    existing = person.memberships
                     .for_club(club)
                     .of_kind(kind)
                     .where("joined_on <= ?", team.season.end_date)
                     .where("left_on IS NULL OR left_on >= ?", team.season.start_date - 90.days)
                     .order(left_on: :desc)
                     .first
    return existing if existing

    # 2. Try to extend the most recent past membership (gap ≤ 90 days)
    last = person.memberships
                 .for_club(club)
                 .of_kind(kind)
                 .where("left_on < ?", team.season.start_date)
                 .order(left_on: :desc)
                 .first

    if last && (team.season.start_date - last.left_on).to_i <= 90
      last.update!(left_on: team.season.end_date)
      return last
    end

    # 3. Create new membership
    left_on = if member.active? && member.club_id == club.id
                nil
    else
                [ member.updated_at.to_date, team.season.end_date ].min
    end

    Membership.create!(
      person: person,
      club: club,
      kind: kind,
      status: left_on.nil? ? :active : :terminated,
      joined_on: team.season.start_date,
      left_on: left_on
    )
  end

  def create_club_assignment(membership, kind_id, starts_on)
    assignment = Assignment.new(
      membership: membership,
      team: nil,
      kind: kind_id,
      status: :active,
      starts_on: starts_on,
      ends_on: nil,
      settings: {}
    )
    assignment.save!
  end

  def create_team_assignment(membership, team, kind_id, jersey_number = nil)
    # Avoid duplicates
    existing = Assignment.find_by(
      membership: membership,
      team: team,
      kind: kind_id
    )
    return if existing

    ends_on = team.season.end_date
    ends_on = nil if ends_on.present? && ends_on > Date.current

    settings = {}
    settings[:jersey_number] = jersey_number if jersey_number.present?

    Assignment.create!(
      membership: membership,
      team: team,
      kind: kind_id,
      status: ends_on ? :terminated : :active,
      starts_on: team.season.start_date,
      ends_on: ends_on,
      settings: settings
    )
  end

  def catch_missing_athlete_assignments
    membership_athlete_kind = Catalog::MembershipKinds[:athlete].id

    missing_pairs = execute(<<~SQL)
      SELECT
        p.id AS player_id,
        e.team_id,
        MIN(DATE(e.start_time)) AS earliest_event,
        MAX(DATE(e.start_time)) AS latest_event
      FROM events_players ep
      JOIN players p ON p.id = ep.player_id
      JOIN events e ON e.id = ep.event_id
      WHERE e.team_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1
          FROM assignments a
          JOIN memberships m ON m.id = a.membership_id
          WHERE m.person_id = p.person_id
            AND m.club_id = e.club_id
            AND m.kind = #{membership_athlete_kind}
            AND a.team_id = e.team_id
        )
      GROUP BY p.id, e.team_id
    SQL

    say "Found #{missing_pairs.count} missing athlete assignments to create."

    missing_pairs.each do |row|
      player = Player.find(row['player_id'])
      team = Team.find(row['team_id'])
      membership = find_or_create_membership(player, team, :athlete)
      next unless membership

      create_team_assignment(membership, team, Catalog::AssignmentKinds.fetch(:athlete).id, player.number)
    end

    say "Created #{missing_pairs.count} missing athlete assignments."
  end
end

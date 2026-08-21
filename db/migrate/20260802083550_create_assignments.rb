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
    coaches = Coach.real
    puts "\n📌 Processing #{coaches.count} coaches..."
    c_count  = 0
    c_teams  = 0
    assigned = 0
    coaches.find_each do |coach|
      c_count += 1
      c_teams += coach.teams.count
      assigned += infer_coach_assignments(coach)
    end
    puts "✅ Processed #{c_count} coaches..."
    puts "\tTeams => #{c_teams}; Assigned => #{assigned}"


    # --- Athletes ---
    puts "\n📌 Processing #{Player.real.count} athletes..."
    assigned = 0
    athlete_kind  = Catalog::AssignmentKinds.fetch(:athlete)
    athlete_pairs = ActiveRecord::Base.logger.silence do
      ActiveRecord::Base.connection.select_all(athlete_pairs_sql).to_a
    end

    athlete_pairs.each do |pair|
      assigned += 1 if infer_athlete_assignment(pair, athlete_kind)
    end
    puts "✅ Processed #{athlete_pairs.count} athlete assignments..."
    puts "\tAssigned => #{assigned}"
  end

  def infer_coach_assignments(coach)
    assigned = 0
    coach.teams.joins(:season).order("seasons.start_date ASC").each do |team|
      # Determine if head or assistant (first in team.coaches order)
      kind = team.coaches.empty? ? :head_coach : :assistant_coach
      assignment_kind = Catalog::AssignmentKinds.fetch(kind)

      membership = find_or_create_membership(coach, team, :coach)
      next unless membership

      if create_team_assignment(membership, team, assignment_kind.id)
        assigned += 1
      end
    end
    # puts "#{assigned} teams assigned."
    assigned
  end

  # Get all distinct player-team pairs via SQL UNION
  def athlete_pairs_sql
    <<~SQL
      SELECT DISTINCT player_id, team_id
      FROM (
        SELECT players.id AS player_id, teams.id AS team_id
        FROM players
        JOIN players_teams ON players_teams.player_id = players.id
        JOIN teams ON teams.id = players_teams.team_id

        UNION

        SELECT events_players.player_id, events.team_id
        FROM events_players
        JOIN events ON events.id = events_players.event_id
        WHERE events.team_id IS NOT NULL
      ) AS all_pairs
    SQL
  end

  def infer_athlete_assignment(athlete, kind)
    player = Player.find_by(id: athlete['player_id'].to_i)
    return nil unless player

    team = Team.find_by(id: athlete['team_id'].to_i)
    return nil unless team

    membership = find_or_create_membership(player, team, :athlete)
    return nil unless membership

    create_team_assignment(membership, team, kind.id, player.number)
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

  def create_team_assignment(membership, team, kind_id, number = nil)
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
    settings[:number] = number if number.present?

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
end

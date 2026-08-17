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

    infer_club_assignments
    infer_team_assignments
  end

  def down
    drop_table :assignments
  end

  private
    def infer_club_assignments
      User.real.each do |user|
        next unless user.club_id

        kind =
          case user.role.to_sym
          when :secretary
            Catalog::AssignmentKinds.fetch(:secretary)
          when :manager
            Catalog::AssignmentKinds.fetch(:club_manager)
          when :admin
            user.is_coach? ? Catalog::AssignmentKinds.fetch(:club_manager) : nil
          end

        next unless kind

        kind = Catalog::AssignmentKinds.entry(kind.id)
        membership = user.person.memberships.current.for_club(user.club_id).of_kind(kind[:membership]).first
        puts "!!! Skipping assignment for User #{user} => NO MEMBERSHIP!" unless membership
        next unless membership

        ass_hash   = start_assignment(membership_id: membership.id, kind: kind.key, starts_on: membership.joined_on)
        assignment = Assignment.new(ass_hash)
        if assignment.save
          puts "* Stored assignment for User #{user} => #{assignment.id}"
        else
          puts "!!! Failed to create assignment for membership #{membership.id}:"
          puts "    Errors: #{assignment.errors.full_messages.join(', ')}"
          puts "assingment_hash = #{ass_hash}"
          raise "Assignment creation aborted"
        end
      end
    end

    def infer_team_assignments
      Team.joins(:season).reorder("seasons.start_date ASC").each do |team|
        infer_team_coaches(team)
        infer_team_players(team)
      end
    end

    def infer_team_coaches(team)
      first_coach = true
      head_coach  = Catalog::AssignmentKinds.fetch(:head_coach)
      asst_coach  = Catalog::AssignmentKinds.fetch(:assistant_coach)
      team.coaches.each do |coach|
        kind       = (first_coach ? head_coach : asst_coach)
        membership = infer_missing_membership(coach, team, :coach)

        # we have a valid assignment to create
        first_coach = false
        create_assignment(membership, team, kind)
      end
    end

    def infer_team_players(team)
      # Gather all (person_id, team_id) pairs from players_teams and events_players
      player_team_pairs = Set.new

      # Current
      team.players.each { |player| player_team_pairs.add([ player.id, team.id ]) }

      # Historical
      Event.joins(:events_players)
           .where(team_id: team.id)
           .pluck("events_players.player_id", :team_id)
           .each { |p, t| player_team_pairs.add([ p, t ]) }


      kind = Catalog::AssignmentKinds.fetch(:athlete)

      player_team_pairs.each do |player_id, team_id|
        puts "* checking for [player_id: #{player_id}, team_id: #{team_id}]"
        player     = Player.find_by(id: player_id)
        next unless player  # skip orphaned references

        membership = infer_missing_membership(player, team, :athlete)
        next unless membership

        # we have a valid assignment to create
        create_assignment(membership, team, kind, player.number)
      end
    end

    def infer_missing_membership(member, team, kind)
      # 1. Find an overlapping membership (including those ending within 90 days before the season)
      existing = member.person.memberships
                       .for_club(team.club)
                       .of_kind(kind)
                       .where("joined_on <= ?", team.season.end_date)
                       .where("left_on IS NULL OR left_on >= ?", team.season.start_date - 90.days)
                       .order(left_on: :desc)
                       .first
      return existing if existing

      # 2. Try to extend the most recent past membership (gap ≤ 90 days)
      last = member.person.memberships
                   .for_club(team.club)
                   .of_kind(kind)
                   .where("left_on < ?", team.season.start_date)
                   .order(left_on: :desc)
                   .first

      if last && (team.season.start_date - last.left_on).to_i <= 90
        # Extend existing membership
        last.update!(left_on: team.season.end_date)
        return last
      end

      # 3. No suitable membership exists – create a new one
      # Determine left_on: use min of updated_at and season end, or nil if still active
      if member.active? && member.club_id == team.club_id
        left_on = nil
        status  = :active
      else
        left_on = [ member.updated_at.to_date, team.season.end_date ].min
        status  = :terminated
      end

      Membership.create!(
        person: member.person,
        club: team.club,
        kind: kind,
        status: status,
        joined_on: team.season.start_date,
        left_on: left_on
      )
    end

    def empty_assignment(membership_id:, kind:)
      { membership_id:, kind:, status: :active }
    end

    def update_assignment(assignment, **attributes)
      assignment.merge!(attributes.compact)
    end

    def start_assignment(membership_id:, kind:, team_id: nil, starts_on:, ends_on: nil)
      assignment = empty_assignment(membership_id:, kind:)
      ends_on  = (ends_on > Date.current ? nil : ends_on) if ends_on
      status   = :terminated if ends_on
      update_assignment(assignment, team_id:, starts_on:, ends_on:, status:)
      assignment
    end

    def create_assignment(membership, team, kind, number = nil)
      assignment = start_assignment(membership_id: membership.id,
        team_id: team.id,
        kind: kind.id,
        starts_on: team.season.start_date,
        ends_on: team.season.end_date)
      assignment[:settings] = { number: } if number.present?

      puts "* Storing assignment for #{membership} => #{assignment}"
      Assignment.create!(assignment)
    end
end

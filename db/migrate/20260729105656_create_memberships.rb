class CreateMemberships < ActiveRecord::Migration[8.0]
  def up
    create_table :memberships, id: :uuid do |t|
      t.references :person, null: false, foreign_key: true
      t.references :club,   null: false, foreign_key: true
      t.integer :kind,   null: false
      t.integer :status, null: false, default: 0
      t.date :joined_on, null: false
      t.date :left_on
      t.timestamps
    end

    add_index :memberships,
              [ :person_id, :club_id, :kind ],
              unique: true,
              where: "left_on IS NULL",
              name: "idx_unique_active_memberships"
    add_index :memberships, :status
    add_index :memberships, :kind

    # ------------------------------------------------------------
    # 1. Club‑level memberships from User records (simple)
    # ------------------------------------------------------------
    infer_club_memberships

    # ------------------------------------------------------------
    # 2. Team‑level memberships (coaches & athletes) – using the
    #    same robust logic as our rake tasks.
    # ------------------------------------------------------------
    infer_team_memberships(:coach)
    infer_team_memberships(:athlete)
  end

  def down
    drop_table :memberships
  end

  private

  # ---- Club memberships ----
  def infer_club_memberships
    User.real.each do |user|
      next unless user.club_id

      kind =
        case user.role.to_sym
        when :secretary then :board_member
        when :manager   then :club_manager
        when :admin     then user.is_coach? ? :club_manager : nil
        else nil
        end
      next unless kind

      membership = start_membership(
        person_id: user.person_id,
        kind: kind,
        club_id: user.club_id,
        joined_on: user.created_at,
        left_on: user.active? ? nil : user.updated_at
      )
      Membership.create!(membership)

      # Admin also gets a board membership
      if user.admin?
        membership[:kind] = :board_member
        Membership.create!(membership)
      end
    end
  end

  # ---- Team memberships (coaches & athletes) ----
  def infer_team_memberships(kind)
    member_class = kind == :coach ? Coach : Player

    member_class.real.find_each do |member|
      # Gather all team IDs this member was ever associated with
      current_team_ids = member.teams.pluck(:id)
      historical_team_ids = []

      if kind == :athlete
        # Athletes: also get teams from events_players
        historical_team_ids = Event.joins(:events_players)
                                   .where(events_players: { player_id: member.id })
                                   .where.not(team_id: nil)
                                   .pluck(:team_id)
                                   .uniq
      end

      all_team_ids = (current_team_ids + historical_team_ids).uniq
      next if all_team_ids.empty?

      # Process teams in chronological order (by season start)
      teams = Team.where(id: all_team_ids)
                  .joins(:season)
                  .order("seasons.start_date ASC")

      membership = nil  # will hold the current membership hash

      teams.each do |team|
        season = team.season
        next unless season

        if membership.nil?
          # Start a new membership
          membership = start_membership(
            person_id: member.person_id,
            kind: kind,
            club_id: team.club_id,
            joined_on: season.start_date,
            left_on: season.end_date
          )
        else
          # Check if this team belongs to the same club and is contiguous
          if membership[:club_id] == team.club_id &&
             contiguous_period?(membership[:left_on], season.start_date)
            # Extend the existing membership
            membership[:left_on] = season.end_date if season.end_date > membership[:left_on]
          else
            # Close the previous membership and start a new one
            membership[:status] = :terminated
            Membership.create!(membership)

            membership = start_membership(
              person_id: member.person_id,
              kind: kind,
              club_id: team.club_id,
              joined_on: season.start_date,
              left_on: season.end_date
            )
          end
        end
      end

      # Finalise the last membership
      if membership
        if member.active? && member.club_id == membership[:club_id]
          membership[:left_on] = nil
          membership[:status] = :active
        else
          membership[:status] = :terminated
        end
        Membership.create!(membership)
      end
    end
  end

  # ---- Helpers ----
  def start_membership(person_id:, kind:, club_id:, joined_on:, left_on:)
    {
      person_id: person_id,
      kind: kind,
      club_id: club_id,
      joined_on: joined_on,
      left_on: left_on,
      status: :active
    }
  end

  def contiguous_period?(previous_end, next_start)
    return false unless previous_end && next_start
    next_start <= previous_end + 90.days
  end
end

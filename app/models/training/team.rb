# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
class Team < ApplicationRecord
  localized_as "training.team"

  before_destroy :unlink

  #-------------------------------------
  # Object relationships
  #-------------------------------------
  belongs_to :club
  belongs_to :category
  belongs_to :division
  belongs_to :season
  belongs_to :sport
  has_many :assignments, dependent: :destroy
  has_and_belongs_to_many :players  # DEPRECATED
  has_and_belongs_to_many :coaches  # DEPRECATED
  has_one :homecourt
  has_one :rules, through: :category
  has_many :slots, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :team_targets, dependent: :destroy
  has_many :targets, through: :team_targets
  accepts_nested_attributes_for :assignments
  accepts_nested_attributes_for :events
  accepts_nested_attributes_for :targets
  accepts_nested_attributes_for :team_targets

  #-------------------------------------
  # Class Scopes & filter fields
  #-------------------------------------
  scope :ordered, -> { order(category_id: :asc) }
  scope :real, -> { where("id>0") }
  scope :for_season, ->(season_id) { (season_id.to_i > 0) ? where(season_id: season_id.to_i) : all }
  scope :for_club, ->(club_id) { (club_id.to_i > 0) ? where(club_id: club_id.to_i) : all }
  FILTER_PARAMS = %i[club_id season_id].freeze


  #-------------------------------------
  # Team common strings
  #-------------------------------------

  # return team name in string format
  def to_s(xls: false)
    if xls
      cad = self.category.to_s.gsub(/[\/|\\|?|*|:|\[|\]]/, "")[0, 27]
      return cad += "_#{self.id.to_s.rjust(3, '0')}"
    end
    return I18n.t("scope.none") if self.id==0
    return self.name if self.name.present?
    return self.nick if self.nick.present?
    self.category.to_s
  end

  # return a sport-specific term
  def term(*parts)
    self.sport.term(parts)
  end

  #-------------------------------------
  # Team member accessors
  #-------------------------------------

  def members(current: false)
    current ?
      assignments.current :
      assignments
  end

  def has_member?(membership, assignment_kind = nil)
    scope = assignments.current.where(membership:)

    scope = scope.of_kind(assignment_kind) if kind.present?

    scope.exists?
  end

  def athletes(current: false)
    members(current:).of_membership_kind(:athlete)
  end

  alias players athletes # DEPRECATED

  def has_athlete?(person_id)
    athletes(current: true)
      .joins(:membership)
      .where(memberships: { person_id: })
      .exists?
  end

  def coaches(current: false)
    members(current:).of_membership_kind(:coach)
  end

  def has_coach?(person_id)
    coaches(current: true)
      .joins(:membership)
      .where(memberships: { person_id: })
      .exists?
  end

  #-------------------------------------
  # Team eligbility
  #-------------------------------------

  # Get a list of athletes that are valid to play in this team
  def eligible_athletes(include_assigned: true)
    scope = club.memberships
                .current
                .of_kind(:athlete)
                .includes(:person)

    scope = scope.merge(Person.for_category(category, season)) # age/sex

    unless include_assigned
      scope = scope.where.not(id: athletes(current: true).select(:membership_id))
    end

    scope
  end

  # Get a list of athletes that are not members but are authorised to play in this team
  def optional_athletes
    eligible_athletes(include_assigned: false)
  end

  #-------------------------------------
  # Team target accessors & checks
  #-------------------------------------

  # collective target filtering methods
  def collective_def(month = 0)
    search_targets(month, 2, 2)
  end

  def collective_off(month = 0)
    search_targets(month, 2, 1)
  end

  # general Team target filtering methods
  def general_def(month = 0)
    search_targets(month, 0, 2)
  end

  def general_off(month = 0)
    search_targets(month, 0, 1)
  end

  # Individual skill target filtering methods
  def individual_def(month = 0)
    search_targets(month, 1, 2)
  end

  def individual_off(month = 0)
    search_targets(month, 1, 1)
  end

  #-------------------------------------
  # Training session helpers
  #-------------------------------------

  # get attendance data for a team in the season
  # returns partial & serialised numbers for attendance: trainings [%]
  def attendance
    t_athletes = self.athletes(current: true).count
    return nil if t_athletes.zero?	# NO ATHLETES IN TEAM --> NO ATTENDANCE DATA

    d_morrow = Date.today + 1	# tomorrow
    d_last7  = d_morrow - 8	# date limit for last 7 days
    d_last30 = d_morrow - 31	# date limit for last 30 days
    l_week   = { tot: 0, att: 0 }
    l_month  = { tot: 0, att: 0 }
    l_season = { tot: 0, att: 0 }
    sessions = { name: sport.specific.term(:athlete, :plural), avg: 0, data: {} }
    t_events = self.events.past.trainings.includes(:events_athletes)
    t_att    = EventAttendance.for_team(self.id)
    t_events.each do |event|
      if event.train?
        e_cnt           = t_att.for_event(event.id).count
        e_date          = event.start_date
        l_season[:tot] += t_athletes
        l_season[:att] += e_cnt
        sessions[:avg] += e_cnt
        if e_date.between?(d_last30, d_morrow)	# event in last month
          l_month[:tot]  += t_athletes
          l_month[:att]  += e_cnt
          if e_date > d_last7	# event occurs in last 7 days
            l_week[:att] += e_cnt
            l_week[:tot] += t_athletes
          end
        end
        sessions[:data][e_date] = e_cnt # add to sessions
      end
    end
    sessions[:week]  = l_week[:tot]>0 ? (100*l_week[:att]/l_week[:tot]).to_i : nil
    sessions[:month] = l_month[:tot]>0 ? (100*l_month[:att]/l_month[:tot]).to_i : nil
    sessions[:avg]   = l_season[:tot]>0 ? (100*l_season[:att]/l_season[:tot]).to_i : nil
    { sessions: sessions }
  end

  # return next free training_slot
  # after the last existing one in the calendar
  def next_slot(last = nil)
    d   = last ? last.start_time.to_date : Date.today	# last planned slot date
    res = nil
    self.slots.each { |slot|
      s   = slot.next_date(d)
      res = res ? (s < res.next_date(d) ? slot : res) : slot
    }
    res
  end

  #-------------------------------------
  # Match/Competition helpers
  #-------------------------------------

  # return potential rival teams - matching category & season
  def rival_teams
    Team.where(sport_id: self.sport_id, season_id: self.season_id, category_id: self.category_id).where.not(club_id: self.club_id)
  end

  # return list of potential rivals - used for text boxes - matching category & season
  def rival_teams_info
    self.rival_teams.map { |team| [ team.nick, team.homecourt_id ] }.to_h
  end

  # Return upcoming events for the Team
  def upcoming_events
    self.events.non_training.short_term
  end

  # return a hash with {won:, lost:} games
  def win_loss
    res     = { won: 0, lost: 0 }
    matches = self.events.matches
    matches.each do |m|
      score = m.total_score # our team first
      if score[:ours][:points] > score[:opps][:points]
        res[:won]  += 1
      elsif score[:opps][:points] > score[:ours][:points]
        res[:lost] += 1
      end
    end
    res
  end

  #-------------------------------------
  # Team builder/update methods
  #-------------------------------------

  # rebuild Teamm from raw hash returned by a form
  def rebuild(f_data)
    self.category_id  = f_data[:category_id].to_i if f_data[:category_id]
    self.club_id      = f_data[:club_id].presence if f_data[:club_id].present?
    self.division_id  = f_data[:division_id].to_i if f_data[:division_id]
    self.homecourt_id = f_data[:homecourt_id].to_i if f_data[:homecourt_id]
    self.name         = f_data[:name].presence if f_data[:name].present?
    self.nick         = f_data[:nick].presence if f_data[:nick].present?
    self.season_id    = f_data[:season_id].to_i if f_data[:season_id]
    self.sport_id     = f_data[:sport_id].to_i if f_data[:sport_id]
    check_targets(f_data[:team_targets_attributes]) if f_data[:team_targets_attributes]
    check_assignments(f_data[:team_assignments_attributes]) if f_data[:team_assignments_attributes]
  end

  # check if drill (or associations) has changed
  def modified?
    changed? ||
      @modified ||
      assignments.any?(&:saved_changes?) ||
      team_targets.any?(&:saved_changes?)
  end

  #-------------------------------------
  # Team class-wide methods
  #-------------------------------------

  # Wrappper to handle creation of a new Team from params
  # received from Teams form, discarding the optional arguments
  def self.build(f_data)
    t_data = f_data.permit(
      :category_id,
      :club_id,
      :division_id,
      :homecourt_id,
      :name,
      :nick,
      :season_id,
      :sport_id
    )
    Team.new(t_data)
  end

  # Apply a Filter to Teams using params received from a controller.
  def self.filter(filters)
    return all unless filters.present?

    club_id  = filters["club_id"]&.to_i
    season_id = filters["season_id"]&.presence

    return all unless club_id || season_id

    scope = for_club(club_id).for_season(season_id)

    filters["column"] ?
      scope.order("#{filters['column']} #{filters['direction']}") :
      scope.order(:name)
  end

  # Search teams for a club matching season
  def self.search(club_id:, season_id: nil)
    scope = for_club(club_id)
    scope = scope.for_season(season_id) if season_id.present?
    scope.order(:category_id)
  end

  private
    #-------------------------------------
    # Rebuild team assignments from form data
    #-------------------------------------
    def check_assignments(data)
      desired = desired_assignments(data)

      ensure_assignments(desired)
      remove_assignments(desired)
      synchronize_legacy_associations
    end

    def desired_assignments(data)
      Array(data).filter_map do |row|
        membership_id = row[:membership_id].presence
        kind          = row[:kind].presence

        next unless membership_id && kind
        next unless club.memberships.exists?(id: membership_id)

        [ membership_id, kind.to_sym ]
      end.uniq
    end


    def ensure_assignments(desired)
      desired.each do |membership_id, kind|
        next if assignments.current.exists?(membership_id:, kind:)

        assignments.create!(
          membership_id:,
          kind:,
          starts_on: Date.current
        )

        @modified = true
      end
    end

    def remove_assignments(desired)
      desired = desired.to_set

      assignments.current.find_each do |assignment|
        next if desired.include?([ assignment.membership_id, assignment.kind.to_sym ])

        assignment.update!(status: :terminated, ends_on: Date.current)
        @modified = true
      end
    end

    #-------------------------------------
    # TEMPORARY COMPATIBILITY
    # TODO: Remove after Player/Coach are unnecessary
    #-------------------------------------
    def synchronize_legacy_associations
      sync_legacy_players
      sync_legacy_coaches
    end

    def sync_legacy_players
      desired_players = athletes(current: true)
        .includes(membership: :person)
        .filter_map { |assignment| assignment.membership.person.player }
        .uniq

      sync_legacy_collection(players, desired_players)
    end

    def synchronize_legacy_coaches
      desired_coaches = coaches(current: true)
        .includes(membership: :person)
        .filter_map { |assignment| assignment.membership.person.coach }
        .uniq

      sync_legacy_collection(coaches, desired_coaches)
    end

    def sync_legacy_collection(association, desired)
      current = association.to_a

      (desired - current).each do |person|
        association << person
        @modified = true
      end

      (current - desired).each do |person|
        association.delete(person)
        @modified = true
      end
    end

    #-------------------------------------
    # Manage team targets from form data
    #-------------------------------------

    # ensure we get the right targets
    def check_targets(t_array)
      a_targets = Target.passed(t_array)
      a_targets.each do |t| # second pass - manage associations
        if t[:_destroy] == "1"	# remove team_target
          TeamTarget.find(t[:id].to_i).delete
          @modified = true
        else	# ensure creation of team_targets
          tt = TeamTarget.fetch(t)
          tt.save unless tt.persisted?
          @modified = true unless self.team_targets.include?(tt)
          self.team_targets ? self.team_targets << tt : self.team_targets |= tt
        end
      end
    end

    # search team_targets based on target attributes
    def search_targets(month = 0, aspect = nil, focus = nil)
      tgt = self.team_targets.monthly(month)
      res = Array.new
      tgt.each do |p|
        if aspect && focus
          res.push p if (p.target.aspect_before_type_cast == aspect) && (p.target.focus_before_type_cast == focus)
        elsif aspect
          res.push p if p.target.aspect_before_type_cast == aspect
        elsif focus
          res.push p if p.target.focus_before_type_cast == focus
        else
          res.push p
        end
      end
      res
    end

    # unlink dependents properly, if deleting team
    def unlink
      UserAction.prune("/clubs/#{self.club.id}/teams/#{self.id}")
    end
end

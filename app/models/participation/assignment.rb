# MudClub - Modular Rails application for managing sports clubs.
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
#
# Assignment
#
# Assigns a Club Member to perform a specific Role either
# at Club level or within a Team.
#
class Assignment < ApplicationRecord
  localized_as "participation.assignment"
  include Auditable
  include Participatory

  belongs_to :membership
  belongs_to :team, optional: true
  has_many :attendances

  # attachment of notes to be handled
  has_rich_text :notes

  # assignment-specific picture can be taken
  has_one_attached :avatar

  # Membership kinds identify the reason why a person belongs to a club.
  # Operational responsibilities are modelled through Participation::Assignment.
  enum :kind,
      Catalog::AssignmentKinds.enum,
      prefix: true

  #-------------------------------------
  # Convenient delegations
  #-------------------------------------
  delegate :club,
          :person,
          :age,
          :birthday,
          :email,
          :female,
          :name,
          :nick,
          :phone,
          :relationships,
          :surname,
          to: :membership

  #-------------------------------------
  # Validations
  #-------------------------------------
  validates :starts_on, presence: true
  validates :kind, presence: true
  validate :team_required

  #-------------------------------------
  # Scopes
  #-------------------------------------
  scope :active, -> { where(ends_on: nil) }
  scope :club_level, -> { where(team_id: nil) }
  scope :team_level, -> { where.not(team_id: nil) }

  scope :for_club, ->(club) {
    joins(:membership).where(memberships: { club_id: club.id })
  }

  scope :for_team, ->(team) {	for_club(team.club).where(team: team) }

  scope :of_kind, ->(kind) { where(kind:) }

  scope :of_membership_kind, ->(kind) {
    joins(:membership).merge(Membership.of_kind(kind))
  }

  scope :search_text, ->(text) {
    return all unless text.present?

    joins(membership: :person)
      .where(memberships: { person_id: Person.search(text) })
  }

  scope :on_date, ->(date = Date.current) {
    where("starts_on <= ?", date)
      .where("ends_on IS NULL OR ends_on >= ?", date)
  }
  scope :terminated, -> { where(status: :terminated) }

  scope :current, -> { where(status: [ :active, :suspended ]) }
  scope :female, -> { joins(:person).where("female = true") }
  scope :male, -> { joins(:person).where("female = false") }
  scope :by_number, -> { order(Arel.sql("NULLIF(settings->>'number', '')::int NULLS LAST")) }

  # short name for form viewing
  def s_name
    person&.s_name || membership.kind_label
  end

  #-------------------------------------
  # General Assignment methods
  #-------------------------------------
  # personal photo or membership kind symbol
  def picture
    return avatar if avatar&.attached?
    return person.avatar if person&.avatar&.attached?

    # if no attached avatar, return the symbol name
    # to be rendered as: symbol_field(symbol)
    kind_image
  end

  def kind_image
    Catalog::AssignmentKinds.normalize(kind) || :person
  end

  def kind_label(...)
    Catalog::AssignmentKinds.val(kind, ...)
  end

  #-------------------------------------
  # Attendance helpers
  #-------------------------------------
  # Is this assingment present in an event?
  def present?(event_id)
    attendances.include?(event_id)
  end

  # get attendance data for player over the period specified by "during"
  # returns attendance inthe form of:
  # matches played and session attendance [%] for week, month and season
  def attendance
    t_events   = team.events.normal.past.includes(:players)
    t_sessions = t_events.trainings
    l_week     = { tot: t_sessions.last7.size, att: 0 }
    l_month    = { tot: t_sessions.last30.size, att: 0 }
    l_season   = { tot: t_sessions.count, att: 0 }
    p_att      = Attendance.for_assignment(self).includes(:event)
    matches    = p_att.matches.size
    t_att      = p_att.trainings
    l_season[:att] = t_att.size
    l_week[:att] = t_att.last7.size
    l_month[:att] = t_att.last30.size
    att_week = l_week[:tot] > 0 ? (l_week[:att] * 100 / l_week[:tot]).to_i : nil
    att_month = l_month[:tot] > 0 ? (l_month[:att] * 100 / l_month[:tot]).to_i : nil
    att_total = l_season[:tot] > 0 ? (100 * l_season[:att] / l_season[:tot]).to_i : nil
    { matches:, last7: att_week, last30: att_month, avg: att_total }
  end

  #-------------------------------------
  # Back-ported methods to replace Player/Coach accesses
  #-------------------------------------
  def age
    person&.age
  end

  def all_pics?
    (avatar&.attached? || person&.avatar&.attached?) &&
      person&.id_front.attached? &&
      person&.id_back.attached?
  end

  def female?
    person&.female?
  end

  # Return email/phone of player or of the associated tutors if underage players
  def p_email
    email = ""
    if age < 18
      person.responsible_adults.each { |par| email += "#{par.person.email.presence}\n" if par.person.email.present? }
    end
    email += email.to_s
  end

  def p_phone
    phone = ""
    if age < 18
      person.responsible_adults.each { |par| phone += "#{par.person.phone.presence}\n" if par.person.phone.present? }
    end
    phone += phone.to_s
  end

  # Return person.to_s or player name and jersey number
  def to_s(style: 2)
    if membership.kind == "athlete"
      case style
      when 0; return self.s_name
      when 1; return self.person.to_s
      when 2; name = self.s_name
      when 3; name = self.person.to_s
      end
      num = "(##{number || "__"})".rjust(5, " ")
      return "#{num} #{name}"
    end

    person&.to_s || membership.kind_label
  end

  # String with number, name & age
  def num_name_age
    "#{number.to_s.rjust(7, " ")}-#{self} (#{age})"
  end

  def number
    settings["number"].presence
  end

  def number=(value)
    self.settings ||= {}
    settings["number"] = value.to_i
  end

  #-------------------------------------
  # Status transitions & definitions
  #-------------------------------------
  def club_assignment?
    team.nil?
  end

  def team_assignment?
    team.present?
  end

  def belongs_to_team?(team)
    team_id == team&.id
  end

  def modified?
    self.changed? ||
      avatar.attachment_changes.present? ||
      person.modified?
  end

  def rebuild(data)
    # only needed for new records
    self.membership_id ||= data[:membership_id] if data[:membership_id].present?

    self.team_id   = data[:team_id]   if data.key?(:team_id)
    self.kind      = data[:kind]      if data.key?(:kind)
    self.status    = data[:status]    if data.key?(:status)
    self.starts_on = data[:starts_on] if data.key?(:starts_on)
    self.ends_on   = data[:ends_on]   if data.key?(:ends_on)
    self.notes     = data[:notes]     if data.key?(:notes)
    self.number    = data[:number]    if data.key?(:number) # only for athletes

    self.update_attachment("avatar", data[:avatar])	if data[:avatar].present?

    return self unless resolve_person(data[:person_attributes])

    self
  end

  def reinstate!(date = Date.current)
    return false unless can_transition_to?(:active)

    transition_to!(:active, :reinstate, date)
  end

  def terminate!(date = Date.current)
    return false unless can_transition_to?(:terminated)

    transition_to!(:terminated, :terminate, date)
  end

  # -------------------------------------------------------------------------
  # Controller façade methods
  # -------------------------------------------------------------------------
  def self.search(club:, search: nil, status: nil, member: nil, team: nil, assignment_kind: nil, membership_kind: nil, history: false)
    scope = team.present? ? for_team(team) : for_club(club)
    scope = scope.where(membership: member) if member.present?
    scope = scope.of_kind(assignment_kind) if assignment_kind.present?
    scope = scope.of_membership_kind(membership_kind) if membership_kind.present?
    scope = scope.search_text(search) if search.present?
    if status
      scope = scope.where(status:)
    else
      scope.current unless history
    end
    scope
  end

  def self.kind_image(kind)
    Catalog::AssignmentKinds.normalize(kind) || :person
  end

  def self.kind_label(kind, ...)
    Catalog::AssignmentKinds.val(kind, ...)
  end

  def self.kind_list
    Catalog::AssignmentKinds.selectable.map do |kind|
      [ self.val(kind), kind ]
    end
  end

  private
    # validate coherent team defined for assignment
    def team_required
      if Catalog::AssignmentKinds.team_level?(kind) && team.blank?
        errors.add(:team, :blank)
      end

      if Catalog::AssignmentKinds.club_level?(kind) && team.present?
        errors.add(:team, :invalid)
      end
    end
end

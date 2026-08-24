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
# Participatory
#
# Group common definitions & methods for Membership/Assignment
#
module Participatory
  extend ActiveSupport::Concern

  included do
    enum :status, {
      pending: 0,
      active: 1,
      suspended: 2,
      terminated: 3,
      archived: 4
    }, prefix: true
  end

  STATUS_TRANSITIONS = {
    pending:    %i[active],
    active:     %i[suspended terminated],
    suspended:  %i[active terminated],
    terminated: %i[active suspended archived],
    archived:   []
  }.freeze

  STATUS_ACTIONS = {
    pending:    %i[activate],
    active:     %i[suspend terminate],
    suspended:  %i[reinstate terminate],
    terminated: [],
    archived:   []
  }.freeze

  #------------------------------------
  # Status flag polling methods
  #------------------------------------
  def active?
    status.to_sym == :active
  end

  def current?
    starts_on.present? &&
      starts_on <= Date.current &&
      (ends_on.nil? || ends_on >= Date.current) &&
      active?
  end

  def open?
    ends_on.nil?
  end

  def started?
    starts_on.present?
  end

  def suspended?
    status.to_sym == :suspended
  end

  def terminated?
    status.to_sym == :terminated
  end

  #------------------------------------
  # Participation UI field methods
  #------------------------------------
  def duration
    return nil unless starts_on

    (ends_on || Date.current) - starts_on
  end

  def date_range
    "#{starts_on} – #{ends_on || I18n.t('shared.statuses.active')}"
  end

  def status_label(variant = nil)
    self.class.status_string(self.status, variant)
  end

  def status_list(variant = nil)
    [ [ status_label, status ] ] +
    available_statuses.map do |st|
      [ self.class.status_string(st, variant), st ]
    end
  end

  class_methods do
    def status_options(include_blank: false, variant: :plural)
      options = statuses.keys.map do |status|
        [ status_string(status, variant), status ]
      end

      include_blank ? [ [ "", nil ] ] + options : options
    end

    def status_string(status, variant = nil)
      key  = "shared.statuses.#{status}"
      key += "_#{variant}" if variant
      I18n.t(key)
    end
  end

  #------------------------------------
  # Status transition methods
  #------------------------------------
  def activate!(date = Date.current)
    transition_to!(:active, :activate, date)
  end

  def reinstate!(date = Date.current)
    return false unless can_transition_to?(:active)

    raise NotImplementedError
  end

  def suspend!(date = Date.current)
    transition_to!(:suspended, :suspend, date)
  end

  def terminate!(date = Date.current)
    return false unless can_transition_to?(:terminated)

    raise NotImplementedError
  end

  #------------------------------------
  # Person resolution & data rebuilding
  #------------------------------------
  def resolve_person(person_attributes)
    return unless person_attributes

    if new_record? || person.nil?
      resolution = Person.resolve(person_attributes)

      case resolution[:status]
      when :ambiguous
        errors.add(:base, Person.msg(:ambiguous))
        return false

      when :new, :probable, :exact
        self.person = resolution[:person]
      end
    end

    person.rebuild(person_attributes)

    true
  end

  private
    #------------------------------------
    # Status transition condition check
    #------------------------------------
    def available_statuses
      STATUS_TRANSITIONS.fetch(status.to_sym, [])
    end

    def can_transition_to?(target_status)
      available_statuses.include?(target_status.to_sym)
    end

    #------------------------------------
    # Unified state transition method
    #------------------------------------
    def transition_to!(target_status, action, date = Date.current)
      return true if status.to_sym == target_status
      return false unless can_transition_to?(target_status)

      transaction do
        old_status  = status.to_sym
        self.status = target_status
        apply_transition_date(action, date)

        save!

        record_status_change(action, from: old_status, to: target_status)
        notify_status_change(action)
      end

      true
    end

    #------------------------------------
    # Audit recording
    #------------------------------------
    def record_status_change(_action, from:, to:)
      # TODO
    end

    #------------------------------------
    # Member/Assignment notifications
    #------------------------------------
    def notify_status_change(_action)
      # TODO
    end

    # Record status change date
    def apply_transition_date(action, date)
      case action
      when :activate
        self.starts_on ||= date
        self.ends_on = nil

      when :terminate
        self.ends_on = date
      end
    end
end

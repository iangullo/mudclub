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
# frozen_string_literal: true

#
# Localizable
#
# Shared localization API for models, catalogs and other domain objects.
#
# Classes including this concern declare their locale scope with:
#
#   localized_as :organization, :club
#
# Examples
#
#   Club.label
#   Club.label(:plural)
#   Club.label(:short)
#
#   Club.fld(:name)
#   Club.msg(:created)
#   Club.val(:athlete)
#
#   Club.term(:athlete)
#   Club.term(:athlete, form: :plural)
#   Club.term(:coach, variant: :short)
#
module Localizable
  extend ActiveSupport::Concern

  #--------------------------------------------------------------------------
  # Translation conventions
  #--------------------------------------------------------------------------

  VARIANT_SUFFIXES = {
    label:       nil,
    short:       "_short",
    hint:        "_hint",
    description: "_description",
    tooltip:     "_tooltip"
  }.freeze

  GRAMMATICAL_FORMS = %i[
    single
    plural
  ].freeze

  TEXT_VARIANTS = %i[
    label
    short
    hint
    description
    tooltip
    home
    won
    lost
    roster
  ].freeze

  #--------------------------------------------------------------------------
  # Configuration
  #--------------------------------------------------------------------------

  included do
    class_attribute :_i18n_scope,
                    instance_accessor: false,
                    default: nil

    class_attribute :_i18n_key_scope,
                    instance_accessor: false,
                    default: :fields
  end

  #--------------------------------------------------------------------------
  # Instance convenience wrappers
  #--------------------------------------------------------------------------

  TRANSLATION_HELPERS = %i[
    label
    term
    fld
    msg
    val
    t_path
  ].freeze

  TRANSLATION_HELPERS.each do |helper|
    define_method(helper) do |*args, **kwargs, &block|
      self.class.public_send(helper, *args, **kwargs, &block)
    end
  end

  #--------------------------------------------------------------------------
  # Class API
  #--------------------------------------------------------------------------

  class_methods do
    #
    # Declares the locale scope used by this class.
    #
    # Example:
    #
    #   localized_as :identity, :person
    #
    def localized_as(*parts)
      self._i18n_scope = parts.flatten.compact.join(".")
    end

    #
    # Declares which subsection key helpers
    # (label(:...), fld, msg, val...) should default to.
    #
    def key_scope(scope)
      self._i18n_key_scope = scope.to_sym
    end

    #
    # Returns the configured locale scope.
    #
    def i18n_scope
      return _i18n_scope if _i18n_scope.present?

      raise NotImplementedError,
            "#{name} must declare localized_as(...) or override .i18n_scope"
    end

    #
    # Default subsection for key lookups.
    #
    def i18n_key_scope
      _i18n_key_scope || :fields
    end

    #--------------------------------------------------------------------------
    # Public translation API
    #--------------------------------------------------------------------------

    #
    # Generic label resolver.
    #
    # Examples
    #
    #   Club.label
    #   Club.label(:plural)
    #   Club.label(:short)
    #
    #   Club.label(:name)
    #   Club.label(:name, scope: :fields)
    #
    def label(key = nil, **options)
      args = normalize_translation_arguments(key, **options)

      if args[:key]
        translate_key_label(**args)
      else
        translate_class_label(**args)
      end
    end

    #
    # Resolves terminology that may be overridden by
    # Club settings or Sport locale.
    #
    # Examples
    #
    #   Club.term(:athlete)
    #   Club.term(:athlete, form: :plural)
    #   Club.term(:coach, variant: :short)
    #
    def term(key, shorthand = nil, variant: :label, form: :single, club: nil, sport: nil, fallback: nil, **options)
      args = normalize_translation_arguments(key, shorthand, **options)

      override_scope =
        if sport
          sport.i18n_scope
        elsif i18n_scope.start_with?("sport.")
          i18n_scope
        end

      Vocabulary.term(
        args[:key],
        form: args[:form],
        variant: args[:variant],
        override_scope:,
        club:,
        fallback:
      )
    end

    #
    # Convenience wrappers
    #
    TRANSLATION_SECTIONS = { fld: :fields, msg: :messages, val: :values }.freeze

    TRANSLATION_SECTIONS.each do |method_name, scope|
      define_method(method_name) do |key, shorthand = nil, **options|
        args = normalize_translation_arguments(key, shorthand, **options)
        translate_key_label(
          key: args[:key],
          scope:,
          variant: args[:variant],
          form: args[:form]
        )
      end
    end

    #
    # Flexible translation path.
    #
    # Relative:
    #
    #   Person.t_path(:fields, :name)
    #
    # Absolute:
    #
    #   Person.t_path("identity.person.fields.name")
    #
    def t_path(*parts, **options)
      key =
        if parts.first.is_a?(String)
          parts.join(".")
        else
          "#{i18n_scope}.#{parts.join('.')}"
        end

      I18n.t(key, **options)
    end

    private

    #--------------------------------------------------------------------------
    # Label argument normalization
    #--------------------------------------------------------------------------

    def normalize_translation_arguments(key = nil, shorthand = nil, scope: nil, variant: :label, form: :single, gender: :neutral, **options)
      if key.is_a?(Symbol)
        if GRAMMATICAL_FORMS.include?(key)
          form = key
          key = nil

        elsif TEXT_VARIANTS.include?(key)
          variant = key
          key = nil
        end
      end

      #
      # val(:athlete, :plural)
      #
      if shorthand
        if GRAMMATICAL_FORMS.include?(shorthand)
          form = shorthand

        elsif TEXT_VARIANTS.include?(shorthand)
          variant = shorthand
        end
      end

      { key:, scope:, variant:, form:, gender:, **options }
    end

    #--------------------------------------------------------------------------
    # Candidate string keys generation
    #--------------------------------------------------------------------------
    def build_candidates(base_key, variant:, form:)
      suffix = +""

      suffix << "_plural" if form == :plural

      if variant != :label
        variant_suffix = VARIANT_SUFFIXES[variant]
        suffix << variant_suffix if variant_suffix
      end

      candidates = []

      if suffix.present?
        candidates << "#{base_key}#{suffix}"
        candidates << "#{base_key}.#{suffix.delete_prefix('_')}"
      else
        candidates << "#{base_key}.#{form}"
      end

      candidates << "#{base_key}.label"
      candidates << base_key

      candidates.uniq
    end

    #--------------------------------------------------------------------------
    # Class labels
    #--------------------------------------------------------------------------

    def translate_class_label(variant:, form:, **)
      lookup_candidates(
        build_candidates("#{i18n_scope}.label", variant:, form:),
        fallback: name.demodulize.titleize
      )
    end

    #--------------------------------------------------------------------------
    # key labels
    #--------------------------------------------------------------------------

    def translate_key_label(key:, scope:, variant:, form:, **)
      section =
        case scope
        when :attribute, :field, :fields
          :fields

        when :message, :messages
          :messages

        when :value, :values
          :values

        else
          i18n_key_scope
        end

      base_key = "#{i18n_scope}.#{section}.#{key}"

      lookup_candidates(
        build_candidates(base_key, variant:, form:),
        fallback: fallback_to_humanize(key, variant, form)
      )
    end

    #--------------------------------------------------------------------------
    # Lookup helpers
    #--------------------------------------------------------------------------
    def lookup_candidates(candidates, fallback:)
      candidates.each do |key|
        value = I18n.t(key, default: nil)

        next if value.blank?

        extracted = extract_translation(value)

        return extracted if extracted.present?
      end

      fallback
    end

    def extract_translation(value)
      return value unless value.is_a?(Hash)

      value[:single] ||
        value["single"] ||
        value[:label] ||
        value["label"]
    end

    #--------------------------------------------------------------------------
    # Fallback
    #--------------------------------------------------------------------------

    def fallback_to_humanize(key, variant, form)
      text = key.to_s.humanize

      text = text.pluralize if form == :plural

      return text if %i[label short].include?(variant)

      case variant
      when :hint
        "#{text} hint"

      when :description
        "#{text} description"

      when :tooltip
        "#{text} tooltip"

      else
        text
      end
    end
  end
end

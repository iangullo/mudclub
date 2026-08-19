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
# Extension of the Sport class to Manage Basketball as a MudClub sport
class Basketball < Sport
  localized_as "sport.basketball"

  #
  # --------------------------------------------------------------------------
  # Initialization
  # --------------------------------------------------------------------------
  def initialize(*args)
    super(*args)
    self.name = "basketball"
    self.settings = basketball_settings if settings.blank?
  end

  # return parent object
  def generic
    self.becomes(Sport)
  end

  #
  # --------------------------------------------------------------------------
  # Catalogs
  # --------------------------------------------------------------------------
  CATALOGS = {
    court_modes: Catalog::Basketball::CourtModes,
    objects: Catalog::Basketball::Objects,
    periods: Catalog::Basketball::Periods,
    rules: Catalog::Basketball::Rules,
    statistics: Catalog::Basketball::Statistics
  }.freeze

  #
  # --------------------------------------------------------------------------
  # Default configuration
  # --------------------------------------------------------------------------

  # return possible court designs for drills/plays
  def court_modes
    catalog(:court_modes)
  end

  #
  # --------------------------------------------------------------------------
  # Match metadata
  # --------------------------------------------------------------------------

  # fields to display match information - not title
  def match_show(event)
    match_fields(event)
  end

  # fields to edit a match
  def match_form(event, new: false)
    match_fields(event, edit: true, new:)
  end

  # return period limitations for a match of this sport
  # depends on rules applied
  def match_outings(rule)
    config = limits_for(rule)
    return nil unless config

    outings = config[:outings] || config["outings"]
    return nil unless outings

    periods = config[:periods] || config["periods"]

    {
      total: periods[:regular] || periods["regular"],
      first: outings[:first] || outings["first"],
      min:   outings[:min] || outings["min"],
      max:   outings[:max] || outings["max"]
    }
  end

  #
  # --------------------------------------------------------------------------
  # Rule helpers
  # --------------------------------------------------------------------------

  # default applicable rules for a category
  def default_rules(category)
    case category.age
    when 0..8   then rules[:u8]
    when 9..10  then rules[:u10]
    when 11..12 then rules[:u12]
    when 13..14 then rules[:u14]
    else             rules[:fiba]
    end
  end

  # fields to show rules limits
  def rules_limits
    res    = rules_limits_title
    limits = self.limits
    rules.enum.each_key do |rule|
      res << rules_limits_row(rule, limits[rule])
    end
    res
  end

  #
  # --------------------------------------------------------------------------
  # Tables
  # --------------------------------------------------------------------------

  # table to show/edit player outings for a match
  def outings_table(event, outings, edit: false, rdx: nil)
    title = [
      { kind: :normal, value: Assignment.attr(:shirt_number_short), align: "center" },
      { kind: :normal, value: Person.attr(:name) }
    ]
    rows  = []
    kind  = (edit ? :text : :normal)
    e_stats    = event.stats
    t_rules    = self.rules.key(event.team.category.rules)
    data       = self.limits[t_rules][:outings]
    data[:tot] = self.limits[t_rules][:periods][:regular]
    data[:act] = self.limits[t_rules][:playing][:max]
    if periods
      q_players = {}
      1.upto(outings[:total]) do |i|
        title << { kind: :normal, value: t_path(:periods, :values, "q#{i}_short".to_sym) }
        q_players[i] = 0
      end
    end
    event.players.order(:number).each do |player|
      p_outings  = 0
      p_stats    = Stat.fetch(player_id: player.id, stats: e_stats, create: false)
      row        = { items: [] }
      row[:url]  = "/players/#{player.id}?event_id=#{event.id}&rdx=#{rdx}" unless edit
      row[:items] << { kind:, value: player.number.to_s, align: "center" }
      row[:items] << { kind:, value: player.s_name }
      1.upto(outings[:total]) do |q|
        q_val = Stat.fetch(period: q, stats: p_stats, create: false).first&.value.to_i
        if edit
          row[:items] << { kind: :checkbox_q, key: :outings, player_id: player.id, q: "q#{q}", value: q_val, align: "center", data: { columnId: "q#{q}" } }
        elsif q_val == 1
          p_outings    += 1 if q <= data[:first]
          q_players[q] += 1
          row[:items] << { kind: :symbol, symbol: { concept: "yes", options: {} }, class: "" }
        else
          row[:items] << { kind: :gap, size: 1, class: "border px py" }
        end
      end
      row[:classes] = (p_outings < data[:min]) || (p_outings > data[:max]) ? [ "border", "px", "py", "bg-red-300" ] : []
      rows << row
    end
    unless edit
      1.upto(outings[:total]) do |i|
        if q_players[i] != data[:act]	# higligh all the Q as "bad"
          rows.each { |row| row[:items][1+i][:class] += " bg-red-300" }
        end
      end
    end
    { title:, rows:, data: }
  end

  # table to show/edit player stats for a match
  def stats_table(event, edit: false, rdx: nil)
    head = match_stats_header(edit:)
    rows = []
    e_stats = event.stats
    event.players.order(:number).each do |player|
      p_stats   = Stat.fetch(player_id: player.id, period: 0, stats: e_stats, create: false)
      row       = { items: [] }
      row[:url] = "/players/#{player.id}?event_id=#{event.id}&rdx=#{rdx}" unless edit
      row[:items] = match_stats_row(player, p_stats, edit:)
      rows << row
    end
    { title: head, rows: rows }
  end

  #
  # --------------------------------------------------------------------------
  # Training
  # --------------------------------------------------------------------------

  # fields to display player's stats for training
  def player_training_stats_show(event, player_id:)
    stats = Stat.fetch(event_id: event.id, period: 0, player_id:, create: false)
    res   = player_training_stats_header
    res << show_shooting_data(s_label("ft"), stats, :ftm, :fta)
    res << show_shooting_data(s_label("tz"), stats, :tzm, :tza)
    res << show_shooting_data(s_label("tm"), stats, :tmm, :tma)
    res << show_shooting_data(s_label("t3"), stats, :t3m, :t3a)
    get_shooting_totals(event.id, player_id, stats)
    res << show_shooting_data(t_path("shared.stats.total_short"), stats, :fgm, :fga)
    res
  end

  # fields to track player training stats
  def player_training_stats_form(event, player_id:)
    key   = "#{player_id}_0_"
    stats = Stat.fetch(event_id: event.id, player_id:)
    res   = player_training_stats_header
    res << form_shooting_data(key, s_label("ft"), stats, :ftm, :fta)
    res << form_shooting_data(key, s_label("tz"), stats, :tzm, :tza)
    res << form_shooting_data(key, s_label("tm"), stats, :tmm, :tma)
    res << form_shooting_data(key, s_label("t3"), stats, :t3m, :t3a)
    res
  end

  #
  # --------------------------------------------------------------------------
  # Symbols
  # --------------------------------------------------------------------------

  # retrieve an SVG symbol from the registry
  def symbol(concept, type: :object, variant: "default")
    try_symbol(concept, namespace: self.name, type:, variant:) || super
  end

  # human name of a specific court
  def court_name(court)
    court_entry =
      case court
      when Catalog::Entry
          court
      when String
        court_modes.fetch(court)
      when Integer
        court_modes.entry(court)
      end

    court_entry.label
  end

  # Some pre-processing of stats_data
  # before parsing normally - grouping & additional calculations
  def parse_stats(event, stats_data)
    event.players.each { |player| parse_player_stats(player.id, stats_data) }
    super(event, stats_data)
  end

  #
  # --------------------------------------------------------------------------
  # Internal helpers
  # --------------------------------------------------------------------------
  private
    # basketball settings
    # TODO: review after last Sport change
    def basketball_settings
      generic_settings.deep_merge(
        scoring: basketball_scoring,
        limits: basketball_limits
      )
    end

    # set default limits applicable to rules
    # {rules(int): {roster: {max:, min:}, playing: {max:, min:}, periods: {regular:, extra:}, outings: {first:, max:, min:}, duration: {regular:, extra:}}}
    def basketball_limits
      limits = {}
      limits[:fiba]  = { roster: { max: 16, min: 5 }, playing: { max: 5, min: 2 }, periods: { regular: 4, extra: 10 }, duration: { regular: 600, extra: 300 } }
      limits[:u14]   = { roster: { max: 16, min: 5 }, playing: { max: 5, min: 2 }, outings: { first: 3, max: 2, min: 1 }, periods: { regular: 4, extra: 10 }, duration: { regular: 600, extra: 300 } }
      limits[:u12]   = { roster: { max: 16, min: 5 }, playing: { max: 5, min: 2 }, outings: { first: 5, max: 3, min: 2 }, periods: { regular: 6, extra: 10 }, duration: { regular: 480, extra: 300 } }
      limits[:u10]   = { roster: { max: 16, min: 5 }, playing: { max: 5, min: 2 }, outings: { first: 3, max: 2, min: 1 }, periods: { regular: 4, extra: 10 }, duration: { regular: 600, extra: 300 } }
      limits[:u8]    = { roster: { max: 16, min: 5 }, playing: { max: 4, min: 2 }, outings: { first: 3, max: 2, min: 1 }, periods: { regular: 4, extra: 10 }, duration: { regular: 480, extra: 300 } }
      limits[:three] = { roster: { max: 5, min: 3 }, playing: { max: 3, min: 2 }, periods: { regular: 1, extra: 10 }, duration: { regular: 420, extra: 180 } }
      limits
    end

    # generic setting method to be used for all setters
    def basketball_scoring
      { sets: false, points: :pts }
    end

    # header fields to show player training_stats
    def player_training_stats_header
      res = [ [ { kind: :gap }, { kind: :side_cell, value: t_path("training.stats.plural"), align: "middle", cols: 5 } ] ]
      res << [
        { kind: :gap },
        topcell(t_path(:shot, :many)),
        topcell(t_path(:shot, :scored)),
        topcell("/"),
        topcell(t_path(:shot, :attempt))
      ]
    end

    # return label for a Baskeball stat
    def s_label(stat, short: true)
      tail = short ? "_short" : ""
      t_path(:stats, "#{stat}#{tail}".to_sym)
    end

    # standardised shooting data fields
    def show_shooting_data(label, stats, scored, attempts)
      s_key = self.stats[scored.to_s]
      a_key = self.stats[attempts.to_s]
      made  = Stat.fetch(concept: s_key, period: 0, stats:).first&.value.to_i
      taken = Stat.fetch(concept: a_key, period: 0, stats:).first&.value.to_i
      pctg  = taken > 0 ? (made*100/taken) : "N/A"
      pcol  = taken == 0 ? "gray-300" : (pctg < 20 ? "red-900": (pctg < 50 ? "yellow-700" : (pctg < 70 ? "gray-700" : "green-700")))
      [
        { kind: :gap },
        stat_label(label),
        { kind: :string, value: made, class: "border px py", align: "right" },
        { kind: :label, value: "/" },
        { kind: :string, value: taken, class: "border px py", align: "right" },
        { kind: :text, value: (taken == 0 ? pctg : "#{pctg}%"), class: "align-middle text-#{pcol}", align: "center" }
      ]
    end

    # add field goal totals to shooting_data stats
    def get_shooting_totals(event_id, player_id, stats)
      made = include_stat_in_event(event_id:, player_id:, period: 0, concept: :fgm)
      made.update(value: sum_stats(stats, SCORED))
      shot = include_stat_in_event(event_id:, player_id:, period: 0, concept: :fga)
      shot.update(value: sum_stats(stats, ATTEMPTS))
    end

    # standardised shooting form fields
    def form_shooting_data(key, label, stats, scored, attempts)
      k_made  = self.stats[scored.to_s]
      v_made  = Stat.fetch(concept: k_made, stats:).first&.value.to_i
      k_taken = self.stats[attempts.to_s]
      v_taken = Stat.fetch(concept: k_taken, stats:).first&.value.to_i
      [
        { kind: :gap },
        stat_label(label),
        { kind: :number_box, key: "#{key}#{k_made}", value: v_made, class: "shots-made border px py", align: "right" },
        { kind: :label, value: "/" },
        { kind: :number_box, key: "#{key}#{k_taken}", value: v_taken, class: "shots-taken border px py", align: "right" }
      ]
    end

    # fields to show the sport rules limits title
    def rules_limits_title
      k_max = t_path("shared.stats.max_short")
      k_min = t_path("shared.stats.min_short")
      k_dur = t_path("shared.stats.qty_short")

      [
        [
          topcell(attr(:rules), rows: 3),
          topcell(term(:period, :plural), cols: 4),
          topcell(Team.attr(:roster), cols: 2, rows: 2),
          topcell(t_path(:outings, :playing), cols: 2, rows: 2),
          topcell(t_path(:outings, :quarter), cols: 3, rows: 2)
        ],
        [
          topcell(t_path(:periods, :regular), cols: 2),	# periods
          topcell(t_path(:periods, :extra), cols: 2)
        ],
        [
          topcell(term(:period, :short)),	# regular
          topcell(k_dur),
          topcell(t_path(:periods, :values, :ot_short)),	# extra
          topcell(k_dur),
          topcell(k_max),	# match roster
          topcell(k_min),
          topcell(k_max),	# match playing
          topcell(k_min),
          topcell(t_path(:outings, :first)),	# outings
          topcell(k_max),	# in field
          topcell(k_min)
        ]
      ]
    end

    # fields for a row of rules limits
    def rules_limits_row(rule, limit)
      g_cls  = "border"
      n_cls  = "#{g_cls} text-center"
      r_per  = limit[:periods]
      r_dur  = limit[:duration]
      r_ros  = limit[:roster]
      r_play = limit[:playing]
      r_out  = limit[:outings] ? limit[:outings] : { "first" => "N/A", "min" => "N/A", "max" => "N/A" }
      [
        { kind: :normal, value: t_path(:rules, "#{rule}_short".to_sym), class: g_cls },
        { kind: :normal, value: r_per[:regular], class: n_cls },
        { kind: :normal, value: r_dur[:regular]/60, class: n_cls },
        { kind: :normal, value: r_per[:extra], class: n_cls },
        { kind: :normal, value: r_dur[:extra]/60, class: n_cls },
        { kind: :normal, value: r_ros[:max], class: n_cls },
        { kind: :normal, value: r_ros[:min], class: n_cls },
        { kind: :normal, value: r_play[:max], class: n_cls },
        { kind: :normal, value: r_play[:min], class: n_cls },
        { kind: :normal, value: r_out[:first], class: n_cls },
        { kind: :normal, value: r_out[:max], class: n_cls },
        { kind: :normal, value: r_out[:min], class: n_cls }
      ]
    end

    # generic match fields generator for show or edit
    def match_fields(event, edit: false, new: false)
      t_pers  = self.match_periods(event.team.category.rules)
      t_cols  = t_pers + (edit ? 3 : 2)
      head    = edit ? [ { kind: :side_cell, value: term(:match, :home), cols: 2, align: "left" } ] : [ { kind: :gap, size: 1 } ]
      t_home  = team_name(event, home: event.home?, edit:)
      t_away  = team_name(event, home: !event.home?, edit:)
      if new
        fields = [ [] ]
        head   = [ { kind: :gap, size: 2 } ] + head
        t_home = [ { kind: :gap, size: 2 } ] + t_home
        t_away = [ { kind: :gap, size: 2 } ] + t_away
      else	# editing an existing match - more fields to show
        fields  = [ [ { kind: :gap, size: 1, cols: t_cols, class: "text-xs" } ] ]
        score   = self.match_score(event.id)
        periods = self.periods
        match_score_fields(event.home?, score, periods, t_pers, head, t_home, t_away, edit:)
        head << topcell(t_path("shared.stats.total_short"))
        team_period_score(event.home?, :tot, t_home, t_away, score[:tot], edit:)
      end
      fields += [ head, t_home, t_away ]
      unless new
        fields << [ { kind: :gap, size: 1, cols: t_pers + 3, class: "text-xs" } ]
        fields << [ { kind: :side_cell, value: term(:athlete, :plural), align: "left", cols: t_cols } ]
      end
      fields
    end

    def match_periods(rule)
      config = limits_for(rule)
      return nil unless config

      periods = config[:periods] || config["periods"]
      return nil unless periods

      periods[:regular] || periods["regular"]
    end

    # fields for home team in a match
    def team_name(event, home:, edit: false)
      if edit
        action = "change->match-location#selectHomeCourt"
        rivals = event.team.rival_teams_info
        if home
          [
            { kind: :radio_button, key: :home, value: true, checked: event.home, align: "right", r_data: { action:, match_location_target: "homeRadio" } },
            { kind: :side_cell, align: "left", value: event.team.to_s }
          ]
        else
          [
            { kind: :radio_button, key: :home, value: false, checked: !event.home, align: "right", r_data: { action: } },
            { kind: :text_box, key: :name, value: event.name, placeholder: term(:rival, :default), options: rivals.keys, size: 12, o_data: { action:, homecourts: rivals.values, match_location_target: "rivalName" } }
          ]
        end
      else	# show
        [ { kind: :side_cell, value: (home ? event.team.to_s : event.name), align: "left" } ]
      end
    end

    # add fields to team period scores
    def team_period_score(home, period, t_home, t_away, val, edit: false)
      p_home = (val ? (home ? val[:ours] : val[:opps]) : 0)
      p_away = (val ? (home ? val[:opps] : val[:ours]) : 0)
      k_tail = "_#{period}_1"
      k_home = "#{(home ? 'ours' : 'opps')}#{k_tail}"
      k_away = "#{(home ? 'opps' : 'ours')}#{k_tail}"
      if edit
        t_home << { kind: :number_box, key: k_home, min: 0, max: 200, size: 2, value: p_home, align: "center" }
        t_away << { kind: :number_box, key: k_away, min: 0, max: 200, size: 2, value: p_away, align: "center" }
      else
        t_home << { kind: :normal, value: p_home, class: "text-center border px py", align: "right" }
        t_away << { kind: :normal, value: p_away, class: "text-center border px py", align: "right" }
      end
    end

    # return a :top_cell field definition
    def topcell(value, cols: nil, rows: nil, align: "center")
      { kind: :top_cell, cols:, rows:, align:, value: }
    end

    # fill head, t_home & t_away the fields for match score
    def match_score_fields(home, score, periods, t_pers, head, t_home, t_away, edit: false)
      rsc = { ours: 0, opps: 0 } # may not need to show overtime scores
      1.upto(t_pers) do |key|
        per = periods.key(key)
        val = score[key]
        if val
          rsc[:ours] += val[:ours]
          rsc[:opps] += val[:opps]
        end
        head << topcell(t_path(:periods, :values, "#{per}_short".to_sym))
        team_period_score(home, per, t_home, t_away, val, edit:)
      end
      if edit || (rsc[:ours] == rsc[:opps] && rsc[:ours] > 0)
        head << topcell(t_path(:periods, :values, :ot_short))
        team_period_score(home, :ot, t_home, t_away, score[:ot], edit:)
      end
    end

    # return fields for stats view
    def match_stats_header(edit: false)
      fields = [
        { kind: :normal, value: t_path("participation.assignment.fields.shirt_number_short"), align: "center" },
        { kind: :normal, value: Person.attr(:name) },
        { kind: :normal, value: s_label(:sec), align: "center" }
      ]
      fields <<	{ kind: :normal, value: s_label(:pts), align: "center" } unless edit
      fields += [
        { kind: :normal, value: s_label(:t2), cols: 3, align: "center" },
        { kind: :normal, value: s_label(:t3), cols: 3, align: "center" },
        { kind: :normal, value: s_label(:ft), cols: 3, align: "center" },
        { kind: :normal, value: s_label(:trb), align: "center" },
        { kind: :normal, value: s_label(:ast), align: "center" },
        { kind: :normal, value: s_label(:stl), align: "center" },
        { kind: :normal, value: s_label(:blk), align: "center" },
        { kind: :normal, value: s_label(:to), align: "center" },
        { kind: :normal, value: s_label(:pfc), align: "center" }
      ]
    end

    # row fields for a player's stats
    def match_stats_row(player, stats, edit: false)
      prefix  = "#{player.id}_0_"

      fields = [
        { kind: :normal, value: player.number, align: "center" },
        { kind: :normal, value: player.s_name },
        stat_field(prefix, stats, statistics.fetch(:sec), edit:)
      ]

      # show points only when not editing
      fields << stat_field(prefix, stats, statistics.fetch(:pts), edit:) unless edit

      fields +=	[
        stat_field(prefix, stats, statistics.fetch(:t2m), edit:),	# 2P shots
        { kind: :normal, value: "/" },
        stat_field(prefix, stats, statistics.fetch(:t2a), edit:),
        stat_field(prefix, stats, statistics.fetch(:t3m), edit:),	# 3P shots
        { kind: :normal, value: "/" },
        stat_field(prefix, stats, statistics.fetch(:t3a), edit:),
        stat_field(prefix, stats, statistics.fetch(:ftm), edit:),	# free throws
        { kind: :normal, value: "/" },
        stat_field(prefix, stats, statistics.fetch(:fta), edit:),
        stat_field(prefix, stats, statistics.fetch(:trb), edit:),	# rebounds
        stat_field(prefix, stats, statistics.fetch(:ast), edit:),	# ast
        stat_field(prefix, stats, statistics.fetch(:stl), edit:),	# stl
        stat_field(prefix, stats, statistics.fetch(:blk), edit:),	# blk
        stat_field(prefix, stats, statistics.fetch(:to), edit:),	# to
        stat_field(prefix, stats, statistics.fetch(:pfc), edit:)	# fouls
      ]
    end

    # parse a player's stats from a form input
    def parse_player_stats(player_id, stats)
      kplay = "#{player_id}_0_"
      pstat = { pta: 0, pts: 0, fga: 0, fgm: 0, t2a: 0, t2m: 0 }
      stats.each_pair do |key, val|
        if key.start_with?(kplay)
          keyarg = key.split("_")
          kplay  = "#{keyarg[0]}_#{keyarg[1]}_"
          kval   = val.to_i
          case keyarg[2].to_i # deal with concepts
          when 3; pstat[:pta] += kval	# free throws
          when 4; pstat[:pts] += kval
          # 5 & 6 total field goals - calculated
          # we'll get either 7 & 8 or 9..12
          when 7;	pstat[:fga] += kval; pstat[:t2a] += kval; pstat[:pta] += (2 * kval)	# Total 2P shots
          when 8;	pstat[:fgm] += kval; pstat[:t2m] += kval; pstat[:pts] += (2 * kval)
          when 9;	pstat[:fga] += kval; pstat[:t2a] += kval; pstat[:pta] += (2 * kval)	# near basket
          when 10; pstat[:fgm] += kval; pstat[:t2m] += kval; pstat[:pts] += (2 * kval)
          when 11; pstat[:fga] += kval; pstat[:t2a] += kval; pstat[:pta] += (2 * kval)	# mid range
          when 12; pstat[:fgm] += kval; pstat[:t2m] += kval; pstat[:pts] += (2 * kval)
          when 13; pstat[:fga] += kval; pstat[:pta] += (3 * kval)	# 3 pointers
          when 14; pstat[:fgm] += kval; pstat[:pts] += (3 * kval)
          end
        end
      end
      stats["#{kplay}1"] = pstat[:pta]
      stats["#{kplay}2"] = pstat[:pts]
      stats["#{kplay}5"] = pstat[:fga]
      stats["#{kplay}6"] = pstat[:fgm]
      stats["#{kplay}7"] = pstat[:t2a]
      stats["#{kplay}8"] = pstat[:t2m]
    end

    # Scoring acumulator for Basketball
    def accumulate_score(total:, ours:, opps:)
      total[:ours] += ours
      total[:opps] += opps
    end
end

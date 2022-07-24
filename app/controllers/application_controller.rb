class ApplicationController < ActionController::Base
  around_action :switch_locale

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  # return grid fields for players with obj indicating
  # => nil: for players index
  # => Team: for team roster views
  def player_grid(players:, obj: nil)
    p_index = (obj == nil)
    title = [{kind: "normal", value: I18n.t("player.number"), align: "center"}, {kind: "normal", value: I18n.t("person.name")}, {kind: "normal", value: I18n.t("person.age"), align: "center"}]
    if p_index
      title << {kind: "normal", value: I18n.t("status.active_a"), align: "center"}
      title << {kind: "add", url: new_player_path, frame: "modal"} if current_user.admin? or current_user.is_coach?
    end
    rows = Array.new
    players.each { | player|
      row = {url: player_path(player), frame: "modal", items: []}
      row[:items] << {kind: "normal", value: player.number, align: "center"}
      row[:items] << {kind: "normal", value: player.to_s}
      row[:items] << {kind: "normal", value: player.person.age, align: "center"}
      if p_index
        row[:items] << {kind: "icon", value: player.active? ? "Yes.svg" : "No.svg", align: "center"}
        row[:items] << {kind: "delete", url: row[:url], name: player.to_s} if current_user.admin? or current_user.is_coach?
      end
      rows << row
    }
    return {title: title, rows: rows}
  end

  # A Field Component with top link + grid for events. obj is the parent oject (season/team)
  def event_grid(events:, obj: nil, retlnk: nil)
    for_season = (obj.class==Season)
    go_back = retlnk ? retlnk : (for_season ? season_events_path(obj) : team_events_path(obj))
    title   = [{kind: "normal", value: I18n.t("calendar.date"), align: "center"}, {kind: "normal", value: I18n.t("calendar.time"), align: "center"}]
    title << {kind: "normal", value: I18n.t("team.single")} if for_season
    title << {kind: "normal", value: I18n.t("drill.desc")}
    rows   = Array.new
    events.each { |event|
      row = {url:  event_path(event, season_id: for_season ? obj.id : nil, retlnk: go_back), frame: event.train? ? "_top" : "modal", items: []}
      row[:items] << {kind: "normal", value: event.date_string, align: "center"}
      row[:items] << {kind: "normal", value: event.time_string, align: "center"}
      row[:items] << {kind: "normal", value: event.team_id > 0 ? event.team.to_s : t("scope.all")} if for_season
      row[:items] << {kind: "normal", value: event.to_s}
      row[:items] << {kind: "delete", url: row[:url], name: event.to_s} if current_user.admin? or (event.team_id>0 and event.team.has_coach(current_user.person.coach_id))
      rows << row
    }
    if for_season
      title << {kind: "add", url: new_event_path(event: {kind: :rest, team_id: 0, season_id: obj.id}), frame: "modal"} if current_user.admin? # new season event
      fields = [[{kind: "link", icon: "calendar.svg", label: I18n.t("calendar.label"), size: "30x30", url: events_path(season_id: @season.id), cols: 4, class: "align-middle text-indigo-900"}]]
    else
      title << new_event_button(obj.id) if obj.has_coach(current_user.person.coach_id) # new team event
      fields = [[
        {kind: "link", icon: "calendar.svg", label: I18n.t("calendar.label"), size: "30x30", url: events_path(team_id: obj.id), class: "align-middle text-indigo-900"},
        {kind: "link", icon: "attendance.svg", label: I18n.t("calendar.attendance"), size: "30x30", url: attendance_team_path(obj), align: "right", frame: "modal", class: "align-middle text-indigo-900"},
        {kind: "gap"}
      ]]
    end
    fields << [{kind: "grid", value: {title: title, rows: rows}, cols: 3}]
    return fields
  end

  # dropdown button definition to create a new Event
  def new_event_button(team_id)
    button = {kind: "add", name: "add-event", options: []}
    button[:options] << {label: I18n.t("train.single"), url: new_event_path(event: {kind: :train, team_id: team_id}), data: {turbo_frame: :modal}}
    button[:options] << {label: I18n.t("match.single"), url: new_event_path(event: {kind: :match, team_id: team_id}), data: {turbo_frame: :modal}}
    button[:options] << {label: I18n.t("rest.single"), url: new_event_path(event: {kind: :rest, team_id: team_id}), data: {turbo_frame: :modal}}
    return {kind: "dropdown", button: button}
  end

  def title_start(icon:, title:, size: nil, rows: nil, cols: nil, _class: nil)
    [[
      {kind: "header-icon", value: icon, size: size, rows: rows, class: _class},
      {kind: "title", value: title, cols: cols}
    ]]
  end

  def form_file_field(label:, key:, value:, cols: nil)
    [[{kind: "upload", label:, key:, value:, cols:}]]
  end

  def drill_search_bar(search_in)
    res = [[
      {kind: "search-combo", url: search_in,
        fields: [
          {kind: "search-text", key: :name, label: I18n.t("person.name_a"), value: session.dig('drill_filters', 'name'), size: 10},
          {kind: "search-select", key: :kind_id, label: "#{I18n.t("kind.single")}:", value: session.dig('drill_filters', 'kind_id'), options: Kind.real.pluck(:name, :id)},
          {kind: "search-select", key: :skill_id, label: I18n.t("skill.single"), value: session.dig('drill_filters', 'skill_id'), options: Skill.real.pluck(:concept, :id)}
        ]
      }
    ]]
  end

  # standardised message wrapper
  def flash_message(message, kind: "info")
    res = {message: message, kind: kind}
  end
end

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
    title = [{kind: "normal", value: I18n.t(:a_num), align: "center"}, {kind: "normal", value: I18n.t(:h_name)}, {kind: "normal", value: I18n.t(:h_age), align: "center"}]
    if p_index
      title << {kind: "normal", value: I18n.t(:a_active), align: "center"}
      title << {kind: "add", url: new_player_path, turbo: "modal"} if current_user.admin? or current_user.is_coach?
    end
    rows = Array.new
    players.each { | player|
      row = {url: player_path(player), turbo: "modal", items: []}
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

  # grid for events. obj is the parent oject (season/team)
  def event_grid(events:, obj:)
    for_season = (obj.class==Season)
    title = [{kind: "normal", value: I18n.t(:h_date), align: "center"}, {kind: "normal", value: I18n.t(:h_time), align: "center"}]
    title << {kind: "normal", value: I18n.t(:l_team_show)} if for_season
    title << {kind: "normal", value: I18n.t(:h_desc)}
    if for_season and current_user.admin? # new season event
      title << {kind: "add", url: new_event_path(event: {kind: :rest, team_id: 0, season_id: obj.id}), turbo: "modal"}
    elsif obj.has_coach(current_user.person.coach_id) # new team event
      title << {kind: "dropdown", button: new_event_button(obj.id)}
    end
    rows = Array.new
    events.each { |event|
      row = {url:  event_path(event, season_id: for_season ? obj.id : nil), turbo: "modal", items: []}
      row[:items] << {kind: "normal", value: event.date_string, align: "center"}
      row[:items] << {kind: "normal", value: event.time_string, align: "center"}
      row[:items] << {kind: "normal", value: event.team_id > 0 ? event.team.to_s : t(:l_all)} if for_season
      row[:items] << {kind: "normal", value: event.to_s}
      row[:items] << {kind: "delete", url: row[:url], name: event.to_s} if current_user.admin? or (event.team_id>0 and event.team.has_coach(current_user.person.coach_id))
      rows << row
    }
    return {title: title, rows: rows}
  end

  # dropdown button definition to create a new Event
  def new_event_button(team_id)
    res = {kind: "add", name: I18n.t(:m_create), options: []}
    res[:options] << {label: I18n.t(:l_train), url: new_event_path(event: {kind: :train, team_id: team_id})}
    res[:options] << {label: I18n.t(:l_match), url: new_event_path(event: {kind: :match, team_id: team_id})}
    res[:options] << {label: I18n.t(:l_rest), url: new_event_path(event: {kind: :rest, team_id: team_id})}
    return res
  end
end

class ApplicationController < ActionController::Base
  around_action :switch_locale

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  # return grid fields for players with 3 variants
  # => "index": for playersindex
  # => "roster": for team roster views
  def players_grid(players:, view: "index")
    head = [{kind: "normal", value: I18n.t(:a_num), align: "center"}, {kind: "normal", value: I18n.t(:h_name)}, {kind: "normal", value: I18n.t(:h_age), align: "center"}]
    if view=="index"
      p_index = true
      head << {kind: "normal", value: I18n.t(:a_active), align: "center"}
      head << {kind: "add", url: new_player_path, modal: true} if current_user.admin? or current_user.is_coach?
    end
    rows = []
    players.each { | player|
      row = {url: player_path(player), modal: true, items: []}
      row[:items] << {kind: "normal", value: player.number, align: "center"}
      row[:items] << {kind: "normal", value: player.to_s}
      row[:items] << {kind: "normal", value: player.person.age, align: "center"}
      if p_index
        row[:items] << {kind: "icon", value: player.active? ? "Yes.svg" : "No.svg", align: "center"}
        row[:items] << {kind: "delete", url: row[:url], name: player.to_s} if current_user.admin? or current_user.is_coach?
      end
      rows << row
    }
    return {header: head, rows: rows}
  end
end

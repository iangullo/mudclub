class HomeController < ApplicationController
  def index
    if current_user.present?
      @title = title_fields
      @teams = team_grid
    end
  end

  private
    def title_fields
      res = [
        [ {kind: "header-icon", value: current_user.picture, class: "rounded-full"},
          {kind: "title", value: current_user.s_name},
          {kind: "edit", url: "/users/" + current_user.id.to_s + "/edit", turbo: "modal"},
          {kind: "link", icon: "key.svg", size: "30x30", class: "align-middle", url: edit_user_registration_path, turbo: "modal"}
        ]
      ]
      res
    end

    def team_grid
      if current_user.teams
        title = [{kind: "normal", align: "center", value: I18n.t(:l_team_index)}]

        rows = Array.new
        current_user.teams.each { |team|
          row = {url: team_path(team), items: []}
          row[:items] << {kind: "normal", value: team.to_s}
          rows << row
        }
  			{title: title, rows: rows}
      else
        nil
      end
    end
end

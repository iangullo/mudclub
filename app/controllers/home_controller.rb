class HomeController < ApplicationController
  def index
    if current_user.present?
      @title = title_fields
      @title << [{kind: "gap"}]
      @teams = team_grid
    end
  end

  def edit
    if current_user.present? and current_user.admin?
      @club  = Person.find(0)
      @fields = [
        [{kind: "header-icon", value: @club.logo}, {kind: "title", value: I18n.t(:m_edit), cols: 2}],
        [{kind: "label", value: I18n.t(:l_name)}, {kind: "text-box", key: :nick, value: @club.nick}]
      ]
      @f_logo = [[{kind: "upload", key: :avatar, label: I18n.t(:l_pic)}]]
    else
      redirect_to "/"
    end
  end

  private
    def title_fields
      res = title_start(icon: current_user.picture, title: current_user.s_name, _class: "rounded-full")
      res.last << {kind: "jump", icon: "key.svg", size: "30x30", url: edit_user_registration_path, turbo: "modal"}
      res
    end

    def team_grid
      if current_user.teams
        title = [{kind: "normal", align: "center", value: I18n.t(:l_team_index)}, {kind: "normal", align: "center", value: I18n.t(:l_sea_show)}]

        rows = Array.new
        current_user.teams.each { |team|
          row = {url: team_path(team), items: []}
          row[:items] << {kind: "normal", value: team.to_s}
          row[:items] << {kind: "normal", value: team.season.name, align: "center"}
          rows << row
        }
  			{title: title, rows: rows}
      else
        nil
      end
    end
end

class HomeController < ApplicationController
  def index
    if current_user.present?
      @title = helpers.home_title_fields
      @title << [{kind: "gap"}]
      @teams = helpers.team_grid(teams: current_user.teams.order(:season_id)) if current_user.teams
    end
  end

  def edit
    check_access(roles: [:admin])
    @club   = Person.find(0)
    @fields = helpers.home_form_fields(club: @club)
    @f_logo = helpers.form_file_field(label: I18n.t("person.pic"), key: :avatar, value: @club.avatar.filename)
  end
end

class HomeController < ApplicationController
  def index
    if current_user.present?
      @teams = current_user.teams
    end
  end
end

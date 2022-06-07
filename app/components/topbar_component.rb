# frozen_string_literal: true

class TopbarComponent < ApplicationComponent
  def initialize(user:)
    @user      = user
    @profile   = profile_menu(user)
    if user
      @menu_tabs = menu_tabs(user)
      @admin_tab = admin_tab(user) if user.admin? or user.is_coach?
    end
  end

  def session_paths(login:, logout:)
    @profile[:login][:url]  = login
    @profile[:logout][:url] = logout
    @profile[:closed][:url] = login
  end

  private
  #right hand profile menu
  def profile_menu(user)
    res = {
      home: menu_link(label: I18n.t(:m_profile), url: '/home/index'),
      login: menu_link(label: I18n.t(:m_login)),
      logout: menu_link(label: I18n.t(:m_logout)),
      closed: menu_button(icon: "login.svg", class: 'login_button rounded hover:bg-blue-700 max-h-8 min-h-6'),
    }
    res[:open] = menu_button(icon: user.picture, class: 'rounded-full h-8 w-8 align-middle') if user
    res
  end

  def menu_tabs(user)
    cls = 'hover:bg-blue-700 hover:text-white whitespace-nowrap shadow rounded px-3 py-3 rounded-md font-semibold'
    res = []
    res << {label: I18n.t(:l_sea_index), url: '/seasons', class: cls} if user.admin?
    if user.teams
      slast = Season.latest
      if slast
        user.teams.each { |team| res << {label: team.name, url: '/teams/'+ team.id.to_s, class: cls} if team.season==slast}
      end
    end
    res << {label: I18n.t(:l_drill_index), url: '/drills', class: cls} if user.is_coach?
    res
  end

  def admin_tab(user)
    clb = 'hover:bg-blue-700 hover:text-white whitespace-nowrap shadow rounded px-3 py-3 rounded-md font-semibold'
    cli = 'hover:bg-blue-700 hover:text-white whitespace-nowrap no-underline block pl-3 pr-3 py-3'
    res = {label: I18n.t(:m_admin), items:[], class: clb}
    res[:items] << {label: I18n.t(:l_team_index), url: '/teams', class: cli}
    res[:items] << {label: I18n.t(:l_player_index), url: '/players', class: cli}
    if user.admin?
      res[:items] << {label: I18n.t(:l_coach_index), url: '/coaches', class: cli}
      res[:items] << {label: I18n.t(:l_user_index), url: '/users', class: cli}
      res[:items] << {label: I18n.t(:l_cat_index), url: '/categories', class: cli}
      res[:items] << {label: I18n.t(:l_div_index), url: '/divisions', class: cli}
    end
    res[:items] << {label: I18n.t(:l_loc_index), url: '/locations', class: cli}
    res
  end


  def menu_button(icon: nil, label: nil, url: nil, class: nil)
    {icon:, label:, url:, class:}
  end

  def dropdown_button
  end

  def menu_link(label:, url: nil)
    {label:, url:, class: 'no-underline block pl-3 pr-3 py-3 hover:bg-blue-700 hover:text-white whitespace-nowrap'}
  end
end

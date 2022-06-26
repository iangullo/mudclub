# frozen_string_literal: true

class TopbarComponent < ApplicationComponent
  def initialize(user:, login:, logout:)
    clubperson = Person.find(0)
    @clublogo  = clubperson.logo
    @clubname  = clubperson.nick
    @user      = user
    @profile   = set_profile(user:, login:, logout:)
    @tabcls    = 'hover:bg-blue-700 hover:text-white focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200 whitespace-nowrap shadow rounded ml-2 px-2 py-2 rounded-md font-semibold'
    @lnkcls    = 'no-underline block pl-2 pr-2 py-2 hover:bg-blue-700 hover:text-white whitespace-nowrap'
    @profcls   = 'align-middle rounded-full min-h-8 min-w-8 align-middle hover:ring-4 hover:ring-blue-200 focus:ring-4 focus:ring-blue-200'
    if user
      @menu_tabs = menu_tabs(user)
      @admin_tab = admin_tab(user) if user.admin? or user.is_coach?
    end
    @prof_tab = prof_tab(user)
    @ham_menu = set_hamburger_menu if user
  end

  private
  #right hand profile menu
  def set_profile(user:, login:, logout:)
    lcls = 'login_button rounded hover:bg-blue-700 max-h-8 min-h-6'
    res  = {
      profile: menu_link(label: I18n.t(:m_profile), url: user, data: {turbo_frame: "modal"}),
      login: menu_link(label: I18n.t(:m_login), url: login),
      logout: menu_link(label: I18n.t(:m_logout), url: logout, data: {turbo_method: :delete}),
      closed: {icon: "login.svg", url: login, class: lcls}
    }
    res[:open] = {icon: user.picture, url: login, class: lcls} if user
    res
  end

  def menu_tabs(user)
    res = []
    res << {label: I18n.t(:l_sea_index), url: '/seasons'} if user.admin?
    if user.teams
      slast = Season.latest
      if slast
        user.teams.each { |team| res << {label: team.name, url: '/teams/'+ team.id.to_s} if team.season==slast}
      end
    end
    res << {label: I18n.t(:l_drill_index), url: '/drills'} if user.is_coach?
    res
  end

  def admin_tab(user)
    res = {kind: "menu", name: "admin", label: I18n.t(:m_admin), options:[], class: @tabcls}
    res[:options] << {label: I18n.t(:l_team_index), url: '/teams'}
    res[:options] << {label: I18n.t(:l_player_index), url: '/players'}
    if user.admin?
      res[:options] << {label: I18n.t(:l_coach_index), url: '/coaches'}
      res[:options] << {label: I18n.t(:l_user_index), url: '/users'}
      res[:options] << {label: I18n.t(:l_cat_index), url: '/categories'}
      res[:options] << {label: I18n.t(:l_div_index), url: '/divisions'}
      res[:options] << {label: @clubname, url: '/home/edit', data: {turbo_frame: "modal"}}
    end
    res[:options] << {label: I18n.t(:l_loc_index), url: '/locations'}
    res
  end

  def prof_tab(user)
    if user
      res = {kind: "menu", name: "profile", icon: user.picture, options:[], class: @profcls}
      res[:options] << {label: @profile[:profile][:label], url: @profile[:profile][:url], class: @lnkcls, data: {turbo_frame: "modal"}}
      res[:options] << {label: @profile[:logout][:label], url: @profile[:logout][:url], class: @lnkcls, data: {turbo_method: :delete}}
    else
      res = {icon: @profile[:closed][:icon], name: "profile", url: @profile[:login][:url], class: @profile[:closed][:class]}
    end
    res
  end

  def set_hamburger_menu
    res = {kind: "menu", name: "hamburger", ham: true, options:[], class: "absolute inset-y-0 left-0 flex items-center sm:hidden inline-block select-none"}
    @menu_tabs.each { |m_opt| res[:options] << m_opt }
    @admin_tab[:options].each { |m_adm| res[:options] << m_adm }
    res
  end

  def menu_link(label:, url: nil, data: nil)
    {label: label, url: url, class: @lnkcls, data: data}
  end
end

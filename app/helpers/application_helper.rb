module ApplicationHelper
  def create_topbar
    TopbarComponent.new(user: user_signed_in? ? current_user : nil)
  end

  def svgicon(icon_name, options={})
    file = File.read(Rails.root.join('app', 'assets', 'images', "#{icon_name}.svg"))
    doc = Nokogiri::HTML::DocumentFragment.parse file
    svg = doc.at_css 'svg'

    options.each {|attr, value| svg[attr.to_s] = value}

    doc.to_html.html_safe
  end

  # generic title start FieldsComponent for views
  def title_start(icon:, title:, size: nil, rows: nil, cols: nil, _class: nil)
    [[
      {kind: "header-icon", value: icon, size: size, rows: rows, class: _class},
      {kind: "title", value: title, cols: cols}
    ]]
  end
end

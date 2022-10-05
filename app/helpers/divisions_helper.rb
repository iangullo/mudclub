module DivisionsHelper
  # return icon and top of FieldsComponent
  def division_title_fields(title:, cols: nil)
    title_start(icon: "division.svg", title: title, cols: cols)
  end
  
  # return FieldsComponent @fields for forms
  def division_form_fields(title:, division:)
    res = division_title_fields(title:, cols: 3)
    res << [{kind: "text-box", key: :name, value: division.name, cols: 3}]
  end
  
  # return grid for @divisions GridComponent
  def division_grid(divisions:)
    title = [{kind: "normal", value: I18n.t("division.name")}]
    title << {kind: "add", url: new_division_path, frame: "modal"} if current_user.admin?
  
    rows = Array.new
    divisions.each { |div|
      row = {url: edit_division_path(div), frame: "modal", items: []}
      row[:items] << {kind: "normal", value: div.name}
      row[:items] << {kind: "delete", url: division_path(div), name: div.name} if current_user.admin?
      rows << row
    }
    {title: title, rows: rows}
  end
end

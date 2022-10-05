module CategoriesHelper
 	# return icon and top of FieldsComponent
 	def category_title_fields(title:, rows: 2, cols: nil)
    title_start(icon: "category.svg", title: title, rows: rows, cols: cols)
  end
  
  # FieldCompoents for category.show
  def category_show_fields(category:)
    res = category_title_fields(title: I18n.t("category.single"), cols: 5, rows: 5)
    res << [{kind: "subtitle", value: category.age_group, cols: 3}, {kind: "subtitle", value: category.sex, cols: 2}]
    res << [{kind: "label", value: I18n.t("stat.min")}, {kind: "string", value: category.min_years}, {kind: "gap"}, {kind: "label", value: I18n.t("stat.max")}, {kind: "string", value: category.max_years}]
    res
  end

  # return FieldsComponent @title for forms
  def category_form_fields(title:, category:)
    res = category_title_fields(title:, rows: 3, cols: 5)
    res << [{kind: "text-box", key: :age_group, value: category.age_group, size: 10, cols: 3}, {kind: "select-box", key: :sex, options: [I18n.t("sex.fem_a"), I18n.t("sex.male_a"), I18n.t("sex.mixed_a")], value: category.sex, cols: 2}]
    res << [{kind: "label", value: I18n.t("stat.min")}, {kind: "number-box", key: :min_years, min: 5, size: 3, value: category.min_years}, {kind: "gap", size: 5}, {kind: "label", value: I18n.t("stat.max")}, {kind: "number-box", key: :max_years, min: 6, size: 3, value: category.max_years}]
	  res << [{kind: "icon", value: "time.svg"}, {kind: "select-box", key: :rules, options: Category.time_rules, value: category.rules ? category.rules : category.def_rules, cols: 4}]
    res
  end

  # return header for @categories GridComponent
  def category_grid(categories:)
    title = [
      {kind: "normal", value: I18n.t("category.name")},
      {kind: "normal", value: I18n.t("sex.label")},
      {kind: "normal", value: I18n.t("stat.min")},
      {kind: "normal", value: I18n.t("stat.max")}
    ]
    title <<  {kind: "add", url: new_category_path, frame: "modal"} if current_user.admin?

    rows = Array.new
    categories.each { |cat|
      row = {url: edit_category_path(cat), frame: "modal", items: []}
      row[:items] << {kind: "normal", value: cat.age_group}
      row[:items] << {kind: "normal", value: cat.sex}
      row[:items] << {kind: "normal", value: cat.min_years, align: "right"}
      row[:items] << {kind: "normal", value: cat.max_years, align: "right"}
      row[:items] << {kind: "delete", url: category_path(cat), name: cat.name} if current_user.admin?
      rows << row
    }
    {title: title, rows: rows}
    end
end

module HomeHelper
  # default title FieldComponents for home page
  def home_title_fields
    res = title_start(icon: current_user.picture, title: current_user.s_name, _class: "rounded-full")
    res.last << {kind: "jump", icon: "key.svg", size: "30x30", url: edit_user_registration_path, frame: "modal"}
    res
  end

  # home edit form fields
  def home_form_fields(club:)
    [
      [{kind: "header-icon", value: club.logo}, {kind: "title", value: I18n.t("action.edit"), cols: 2}],
      [{kind: "label", value: I18n.t("person.name_a")}, {kind: "text-box", key: :nick, value: club.nick}]
    ]
  end
end

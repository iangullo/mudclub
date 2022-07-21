module DrillsHelper
  # return FieldComponent fields for skills
  def skills_form(skill: nil)
    res     = []
    if skill
     res << [{kind: "text-box", key: :concept, size: 10, value: skill.concept, placeholder: I18n.t("skill.default")}]
     res.last << {kind: "hidden", key: :_destroy}
#       res.last << btn_del
    else
      @drill.skills.each { |skill|
        res << [{kind: "text-box", key: :concept, size: 10, value: skill.concept, placeholder: I18n.t("skill.default")}]
        res.last << {kind: "hidden", key: :_destroy}
#          res.last << btn_del
      }
     end
    res
  end
end

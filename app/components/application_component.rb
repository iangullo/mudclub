# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  def initialize(tag: nil, classes: nil, **options)
    @tag = tag
    @classes = classes
    @options = options
  end

  def call
    content_tag(@tag, content, class: @classes, **@options) if @tag
  end

  def tablecell_tag(item, tag=:td)
    tag(tag,
      colspan: item[:cols] ? item[:cols] : nil,
      rowspan: item[:rows] ? item[:rows] : nil,
      align: item[:align] ? item[:align] : nil,
      class: item[:class] ? item[:class] : nil
    )
  end
end

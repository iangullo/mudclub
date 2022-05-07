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
end

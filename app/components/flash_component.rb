# frozen_string_literal: true

class FlashComponent < ApplicationComponent
  def initialize(notice:)
    @count  = @count ? @count + 1 : 1
    @notice = notice.class==String ? notice : notice["message"]
    @kind   = notice.class==String ? "info" : notice["kind"]
    case @kind
    when "error"
      color = "red"
    when "success"
      color = "indigo"
    else
      color = "gray"
    end
    @d_class = "flex p-4 mb-4 bg-#{color}-100 text-#{color}-900 text-sm rounded-lg shadow-lg"
    @b_class = "ml-auto -mx-1.5 -my-1.5 rounded-lg focus:ring-2 focus:ring-#{color}-400 p-1.5 hover:bg-#{color}-200 inline-flex h-8 w-8"
  end
end

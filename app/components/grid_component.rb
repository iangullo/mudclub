# frozen_string_literal: true

class GridComponent < ApplicationComponent
  render_one: :g_head
  render_many: :g_rows

  def initialize(g_head:, g_rows:)
    @g_head = g_head
    @g_rows = g_rows
  end

end

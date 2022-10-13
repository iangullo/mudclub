# frozen_string_literal: true

class ModalPieComponent < ApplicationComponent
	def initialize(header:, chart: {})
		@view_header = header
		@chart_title = chart[:title]
		@chart_data  = chart[:data]
	end
end

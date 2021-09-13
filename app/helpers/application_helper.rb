module ApplicationHelper
  # read new field value, keep old value if empty & possible
	def read_field(dat_value, old_value, def_value)
		if dat_value	# we read & assign
			read_field = datum.value.to_s
		else	# assign default if no old value exists
			read_field = "def_value" unless old_value
		end
	end
end

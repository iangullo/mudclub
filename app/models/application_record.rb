class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # read new field value, keep old value if empty & possible
	def read_field(dat_value, old_value, def_value)
    if dat_value    # we read & assign
      read_field = (dat_value.class == String) ? dat_value : dat_value.value.to_s
    else    # assign default if no old value exists
      read_field = def_value unless old_value
    end
  end

  # return a 2 digit string for a number
  def two_dig(num)
		num.to_s.rjust(2,'0')
	end

  	# starting / ending hours as string
	def timeslot_string(t_begin:, t_end: nil)
		cad = two_dig(t_begin.hour) + ":" + two_dig(t_begin.min)
    cad = cad + "-" + two_dig(t_end.hour) + ":" + two_dig(t_end.min) if t_end
    cad
	end
end

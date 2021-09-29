class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # read new field value, keep old value if empty & possible
	def read_field(dat_value, old_value, def_value)
    if dat_value    # we read & assign
      read_field = (dat_value.class == String) ? dat_value : dat_value.value.to_s
    else    # assign default if no old value exists
      read_field = def_value unless old_value
    end
  end
end

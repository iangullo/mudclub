# Manage Basketball rules / stats, etc.
class BasketballSport < Sport
	# Getter method for accessing the settings hash
	def settings
    super&.symbolize_keys || {}
	end

	# Setter method for updating the settings hash
	def settings=(value)
		super(value&.to_h)
	end

	# Getter method for accessing the Sport rules mapping
	def rules
		settings&.fetch(:rules, {})
	end

	# the default rules to apply in a category
	def def_rules

	end

	# Setter method for updating the rules mapping
	def rules=(value)
		set_setting(:rules, value)
	end

	# Getter method for accessing the stat mapping
	def stats
		settings&.fetch(:stats, {})
	end

	# Setter method for updating the stat mapping
	def stats=(value)
		set_setting(:stats, value)
	end

	# Getter method for accessing the Sport rules mapping
	def stat_kinds
		settings&.fetch(:stat_kinds, {})
	end

	# Setter method for updating the rules mapping
	def stat_kinds=(value)
		set_setting(:stat_kinds, value)
	end

	private
	# generic setting method to be used for all setters
	def set_setting(key, value)
		self.settings = settings.merge(key => value)
	end
end

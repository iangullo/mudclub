
#
# Catalog::MembershipKinds
#
# Defines the recognised categories of membership within a club.
#
# Membership kinds describe why a person belongs to a club.
#
# Each kind declares the organisational modules in which members
# of that kind normally participate. Members may simultaneously hold
# multiple memberships, allowing them to contribute across several
# organisational domains.
#
class Catalog::StatKinds < Catalog::Base
	domain "participation"

	CATALOG = {

		team: {
			id: 0,
			description:
				"Totalling stats for own team."
		},

		rival: {
			id: 1,
			description:
				"Totalling stats for rival team."
		},

		athlete: {
			id: 2,
			description:
				"Stats for an individual athlete."
		}
	}.freeze

	def self.normalize(value)
		super(value)&.to_s&.singularize&.to_sym
	end
end

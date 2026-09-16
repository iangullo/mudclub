# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
# app/helpers/routing_helper.rb
module RoutingHelper
	#
	# --------------------------------------------------------------------------
	# Routing hierarchy
	# --------------------------------------------------------------------------
	#

	def resource_route(record, owner: @owner, club: @club)
		raise ArgumentError, "expected an instance, got #{record.inspect}" if record.is_a?(Class)

		case record

		when Category, Division, Location
			[ owner, record ]

		when Document
			case owner
			when Club, User
				[ owner, record ]

			when Registration
				[ club, owner, record ]
			else
				raise ArgumentError, "Unsupported document owner #{owner.inspect}"
			end

		when Registration, Membership, Slot, Team
			[ record.club, record ]

		when Assignment
			record.team ? [ record.club, record.team, record ] :
										[ record.club, record.membership, record ]

		when Event
			record.team ? [ record.club, record.team, record ] :
										[ record.club, record ]

		when Task
			resource_route(record.event)

		else	# including Club, Drill, Season, Sport, User, ...
			[ record ]
		end
	end

	#
	# --------------------------------------------------------------------------
	# Generic CRUD paths
	# --------------------------------------------------------------------------
	#
	def path_for(record, action: nil, owner: @owner, club: @club, rdx: @rdx, **options)
		base   = resource_route(record, owner:, club:)
		target = action ? [ action, *base ] : base
		polymorphic_path(target, rdx: rdx, **options)
	end

	def edit_path_for(record, owner: @owner, club: @club, rdx: @rdx, **options)
		path_for(record, owner:, club:, action: :edit, rdx:, **options)
	end

	def destroy_path_for(record, owner: @owner, club: @club, rdx: @rdx, **options)
		path_for(record, owner:, club:, rdx:, **options)
	end

	def new_path_for(parent, child_symbol, owner: @owner, club: @club, rdx: @rdx, **options)
		polymorphic_path(
			[ :new, *resource_route(parent, owner:, club:), child_symbol ],
			rdx:,
			**options
		)
	end

	# ----------------------------------------------------------------------------
	# Navigation: parent page and collection index
	# ----------------------------------------------------------------------------

	# Parent page for `record` — e.g. from a Document under a Club, the Club's show page.
	# Returns nil for top-level resources (Club, Sport, User, Drill, Season).
	def base_path(record, owner: @owner, club: @club, rdx: @rdx, **options)
		parents = parents_of(record, owner:, club:)
		parents && polymorphic_path(parents, rdx:, **options)
	end

	# Collection index for `record`'s class, nested under the same parents as `path_for`.
	# e.g. TeamEvent -> club_team_events_path; Membership -> club_members_path.
	def return_path_for(record, owner: @owner, club: @club, rdx: @rdx, **options)
		parents = parents_of(record, owner:, club:) || []
		polymorphic_path([ *parents, collection_key_for(record) ], rdx:, **options)
	end

	private
		# Collection route key for a record's class — resolves to :members for
		# Membership via the model-level model_name override.
		def collection_key_for(record)
			record.class.model_name.route_key.to_sym
		end

		def parents_of(record, owner:, club:)
			chain = resource_route(record, owner:, club:)
			chain.length < 2 ? nil : chain[0..-2]
		end
end

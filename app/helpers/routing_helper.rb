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

		when Category, Division
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

		when Location, Slot
			[ club, record ]

		when Registration, Membership, Team
			[ record.club, record ]

		when Assignment
			record.team ? [ record.club, record.team, record ] :
										[ record.club, record ]

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
		options.merge!(rdx_options(rdx))
		base   = resource_route(record, owner:, club:)
		target = action ? [ action, *base ] : base
		polymorphic_path(target, **options)
	end

	def edit_path_for(record, owner: @owner, club: @club, rdx: @rdx, **options)
		options.merge!(rdx_options(rdx))
		path_for(record, owner:, club:, action: :edit, **options)
	end

	def destroy_path_for(record, owner: @owner, club: @club, rdx: @rdx, **options)
		options.merge!(rdx_options(rdx))
		path_for(record, owner:, club:, **options)
	end

	def new_path_for(parent, child_symbol, owner: @owner, club: @club, rdx: @rdx, **options)
		options.merge!(rdx_options(rdx))
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
		options.merge!(rdx_options(rdx))
		parents = parents_of(record, owner:, club:)
		parents && polymorphic_path(parents, **options)
	end

	# Collection index for `record`'s class, nested under the same parents as `path_for`.
	# e.g. TeamEvent -> club_team_events_path; Membership -> club_members_path.
	def return_path_for(record, owner: @owner, club: @club, rdx: @rdx, **options)
		parents = parents_of(record, owner:, club:) || []
		opts    = options.merge(rdx_options(rdx))
		case rdx&.to_i
		when 0, nil
			polymorphic_path([ *parents, collection_key_for(record) ], **opts)
		when 1
			user_path(current_user, **opts)
		when 2
			home_log_path(**opts)
		when 3
			if params[:member_id].present?
				club_member_path(club:, **opts)
			elsif params[:user_id].present?
				user_path(params[:user_id], **opts)
			else
				polymorphic_path([ *parents, collection_key_for(record) ], **opts)
			end
		else
			root_path
		end
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

		def rdx_options(rdx = @rdx, kind: nil)
			opts      = { rdx:, status: @status || params[:status].presence }
			member_id = @member&.id || params[:member_id].presence
			if member_id
				opts[:kind]      = kind || @kind || params[:kind].presence
				opts[:member_id] = member_id
			elsif (user_id = @user&.id || params[:user_id].presence)
				opts[:user_id] = user_id if user_id
			end
			opts
		end
end

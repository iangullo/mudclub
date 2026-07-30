class CreateAssignments < ActiveRecord::Migration[8.0]
	def up
		create_table :assignments, id: :uuid do |t|
			t.references :membership, type: :uuid, null: false, foreign_key: true
			t.references :team, foreign_key: true

			t.integer :kind,   null: false
			t.integer :status, null: false, default: 0
			t.jsonb :settings, default: {}


			t.date :starts_on, null: false
			t.date :ends_on

			t.timestamps
		end

		infer_club_assignments
		infer_team_assignments
	end

	def down
		drop_table :assignments
	end

	private
		def infer_club_assignments
			User.real.each do |user|
				next unless user.club_id

				kind =
					case user.role.to_sym
					when :secretary
						Catalog::AssignmentKinds.fetch(:secretary)
					when :manager
						Catalog::AssignmentKinds.fetch(:club_manager)
					when :admin
						user.is_coach? ? Catalog::AssignmentKinds.fetch(:club_manager) : nil
					end

				next unless kind

				kind = Catalog::AssignmentKinds.entry(kind.id)
				membership = user.person.memberships.current.for_club(user.club_id).of_kind(kind[:membership]).first
				puts "!!! Skipping assignment for User #{user} => NO MEMBERSHIP!" unless membership
				next unless membership

				assignment =
					start_assignment(membership_id: membership.id, kind: kind.id,
						starts_on: membership.joined_on)
				puts "* Storing assignment for User #{user} => #{assignment}"
				Assignment.create!(assignment)
			end
		end

		def infer_team_assignments
			Team.joins(:season).reorder("seasons.start_date ASC").each do |team|
				first_coach = true
				head_coach  = Catalog::AssignmentKinds.fetch(:head_coach)
				asst_coach  = Catalog::AssignmentKinds.fetch(:assistant_coach)
				team.coaches.each do |coach|
					kind = (first_coach ? head_coach : asst_coach)
					membership = infer_missing_membership(coach, team, :coach)

					# we have a valid assignment to create
					assignment = start_assignment(membership_id: membership.id,
						team_id: team.id,
						kind: kind.id,
						starts_on: team.season.start_date,
						ends_on: team.season.end_date)
					first_coach = false
					puts "* Storing assignment for Coach #{coach} => #{assignment}"
					Assignment.create!(assignment)
				end

				kind = Catalog::AssignmentKinds.fetch(:athlete)
				team.players.each do |player|
					membership = infer_missing_membership(player, team, :athlete)

					# we have a valid assignment to create
					assignment = start_assignment(membership_id: membership.id,
						team_id: team.id,
						kind: kind.id,
						starts_on: team.season.start_date,
						ends_on: team.season.end_date)
					puts "* Storing assignment for Player #{player} => #{assignment}"
					Assignment.create!(assignment)
				end
			end
		end

		def infer_missing_membership(member, team, kind)
			membership = member.person.memberships.current.for_club(team.club_id).of_kind(kind).first
			return membership if membership

			if member.active? && team.season.end_date > Date.today
				status  = :active
				left_on = nil
			else
				status  = :terminated
				left_on = [ member.updated_at.to_date, team.season.end_date ].max
			end

			puts "WARNING! Inferred historical #{kind} membership for #{member}"
			Membership.create!(
				person: member.person,
				club: team.club,
				kind:,
				status:,
				joined_on: team.season.start_date,
				left_on:
			)
		end

		def empty_assignment(membership_id:, kind:)
			{ membership_id:, kind:, status: :active }
		end

		def update_assignment(assignment, **attributes)
			assignment.merge!(attributes.compact)
		end

		def start_assignment(membership_id:, kind:, team_id: nil, starts_on:, ends_on: nil)
			assignment = empty_assignment(membership_id:, kind:)
			ends_on  = (ends_on > Date.current ? nil : ends_on) if ends_on
			status   = :terminated if ends_on
			update_assignment(assignment, team_id:, starts_on:, ends_on:, status:)
			assignment
		end
end

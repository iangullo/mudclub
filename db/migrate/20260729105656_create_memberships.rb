class CreateMemberships < ActiveRecord::Migration[8.0]
	def up
		create_table :memberships, id: :uuid do |t|
			t.references :person, null: false, foreign_key: true
			t.references :club,   null: false, foreign_key: true

			t.integer :kind,   null: false
			t.integer :status, null: false, default: 0

			t.date :joined_on, null: false
			t.date :left_on

			t.timestamps
		end

		add_index :memberships,
							[ :person_id, :club_id, :kind ],
							unique: true,
							where: "left_on IS NULL",
							name: "idx_unique_active_memberships"

		add_index :memberships, :status
		add_index :memberships, :kind

		# Create inferred membership history
		infer_team_memberships(:coach)
		infer_team_memberships(:athlete)
		infer_club_memberships
	end

	def down
		drop_table :memberships
	end

	private
		def infer_club_memberships
			User.real.each do |user|
				if user.club_id
					kind =
						case user.role.to_sym
						when :secretary then :board_member
						when :manager then :club_manager
						when :admin
							user.is_coach? ? :club_manager : nil
						else
							nil
						end

					kind = kind&.to_sym
					if kind # we have a valid membership to create
						membership =
							start_membership(person_id: user.person_id, kind:,
								club_id: user.club_id,
								joined_on: user.created_at,
								left_on: user.active? ? nil : user.updated_at
							)
						puts "* Storing membership for User #{user} => #{membership}"
						Membership.create!(membership)
						if user.admin?  # add board membership
							membership[:kind] = :board_member
							puts "* Storing membership for User #{user} => #{membership}"
							Membership.create!(membership)
						end
					end
				end
			end
		end

		def infer_team_memberships(kind)
			member_class =
				case kind
				when :coach then Coach
				when :athlete then Player
				else
					raise ArgumentError, "Unknown team membership kind: #{kind}"
				end

			member_class.real.each do |member|
				membership = empty_membership(person_id: member.person_id, kind:)

				member.teams.joins(:season).reorder("seasons.start_date").each do |team|
					season = team.season

					unless membership[:club_id]  # we had no active membership
						initialize_membership(membership, club_id: team.club_id, joined_on: season.start_date, left_on: season.end_date)
					else  # had an active membership
						if same_membership?(membership, team, season)  # extend period
							extend_membership!(membership, season)
						else  # commit terminated membership, cleanup temp object
							membership[:status] = :terminated
							puts "* Storing membership for #{member} => #{membership}"
							Membership.create!(membership)
							membership =
								start_membership(person_id: member.person_id, kind:,
									club_id: team.club_id,
									joined_on: season.start_date,
									left_on: season.end_date
								)
						end
					end
				end
				if membership[:club_id] # final commit
					member.active? ? membership[:left_on] = nil : membership[:status] = :terminated
					puts "* Storing membership for #{member} => #{membership}"
					Membership.create!(membership)
				end
			end
		end

		def empty_membership(person_id:, kind:)
			{ person_id:, kind:, status: :active }
		end

		def initialize_membership(membership, **attributes)
			membership.merge!(attributes.compact)
		end

		def start_membership(person_id:, kind:, club_id:, joined_on:, left_on:)
			membership = empty_membership(person_id:, kind:)
			initialize_membership(membership, club_id:, joined_on:, left_on:)
			membership
		end

		def same_membership?(membership, team, season)
			membership[:club_id] == team.club_id &&
				contiguous_period?(membership[:left_on], season.start_date)
		end

		def contiguous_period?(previous_end, next_start)
			return false unless previous_end && next_start
			next_start <= previous_end + 90.days
		end

		def extend_membership!(membership, season)
			membership[:left_on] = season.end_date if season.end_date > membership[:left_on]
		end
end

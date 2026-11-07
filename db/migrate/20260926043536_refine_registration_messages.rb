class RefineRegistrationMessages < ActiveRecord::Migration[8.0]
	def up
		# 1. Author is an Assignment (uuid), nullable.
		#    nil + author_kind discriminates requester vs system.
		add_column :registration_messages, :author_assignment_id, :uuid
		add_index  :registration_messages, :author_assignment_id
		add_foreign_key :registration_messages, :assignments,
										column: :author_assignment_id

		# 2. Collapse the two booleans into one visibility enum.
		add_column :registration_messages, :visibility, :integer,
							null: false, default: 0

		# 3. Backfill: internal OR not-visible-to-requester → internal (1)
		execute <<~SQL
      UPDATE registration_messages
         SET visibility = 1
       WHERE internal = TRUE
          OR visible_to_requester = FALSE
		SQL

		# 4. Drop the old booleans.
		remove_column :registration_messages, :internal
		remove_column :registration_messages, :visible_to_requester

		# 5. Composite index for the common query: "this registration's
		#    requester-visible messages, chronological".
		add_index :registration_messages,
							[ :registration_id, :visibility, :created_at ],
							name: "idx_reg_msgs_on_reg_visibility_created"
	end

	def down
		add_column :registration_messages, :visible_to_requester, :boolean,
							default: true, null: false
		add_column :registration_messages, :internal, :boolean,
							default: false, null: false

		execute <<~SQL
      UPDATE registration_messages
         SET internal = (visibility = 1),
             visible_to_requester = (visibility = 0)
		SQL

		remove_index :registration_messages,
								name: "idx_reg_msgs_on_reg_visibility_created"
		remove_column :registration_messages, :visibility

		remove_foreign_key :registration_messages, column: :author_assignment_id
		remove_index  :registration_messages, :author_assignment_id
		remove_column :registration_messages, :author_assignment_id
	end
end

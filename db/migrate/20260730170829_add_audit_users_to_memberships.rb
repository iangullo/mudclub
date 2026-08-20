class AddAuditUsersToMemberships < ActiveRecord::Migration[8.0]
  class Membership < ApplicationRecord
    self.table_name = "memberships"
  end

  class MembershipKind < ApplicationRecord
    self.table_name = "membership_kinds"
  end

  class User < ApplicationRecord
    self.table_name = "users"
  end

  class MembershipRecord < ApplicationRecord
    self.table_name = "memberships"
  end

  def up
    add_reference :memberships,
                  :created_by,
                  foreign_key: { to_table: :users },
                  index: true

    add_reference :memberships,
                  :updated_by,
                  foreign_key: { to_table: :users },
                  index: true

    say_with_time "Assigning audit users to existing memberships" do
      manager_kind = Catalog::MembershipKinds[:club_manager].id
      MembershipRecord.find_each do |membership|
        manager_user_id =
          first_club_manager(membership.club_id, manager_kind)

        next unless manager_user_id

        membership.update_columns(
          created_by_id: manager_user_id,
          updated_by_id: manager_user_id
        )
      end
    end
  end

  def down
    def down
      # Explicitly remove foreign keys (if they exist)
      if foreign_key_exists?(:memberships, column: :created_by_id)
        remove_foreign_key :memberships, column: :created_by_id
      end
      if foreign_key_exists?(:memberships, column: :updated_by_id)
        remove_foreign_key :memberships, column: :updated_by_id
      end

      # Remove columns safely (if they still exist)
      remove_column :memberships, :created_by_id if column_exists?(:memberships, :created_by_id)
      remove_column :memberships, :updated_by_id if column_exists?(:memberships, :updated_by_id)
    end
  end

  private

  def first_club_manager(club_id, manager_kind)
    execute(<<~SQL).first&.fetch("user_id")
      SELECT people.user_id
        FROM memberships
        JOIN people
          ON people.id = memberships.person_id
      WHERE memberships.club_id = #{club_id}
        AND memberships.kind = #{manager_kind}
        AND memberships.left_on IS NULL
      ORDER BY memberships.created_at, memberships.id
      LIMIT 1
    SQL
  end
end

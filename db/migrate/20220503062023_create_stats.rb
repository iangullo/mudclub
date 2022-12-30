# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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
class CreateStats < ActiveRecord::Migration[6.1]
  def change
    create_table :stats do |t|
      t.belongs_to :event, null: false, foreign_key: true
      t.belongs_to :player, null: false, foreign_key: true
      t.integer :concept
      t.integer :value

      t.timestamps
    end
    Player.create(id: -1, number: 0, active: false, person_id: 0) # fake player to track rival stats
  end
end

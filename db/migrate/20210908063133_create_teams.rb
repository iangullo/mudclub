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
class CreateTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.references :season, null: false, foreign_key: true, default: 0
      t.references :category, null: false, foreign_key: true, default: 0
      t.references :division, null: false, foreign_key: true, default: 0

      t.timestamps
    end
    add_reference :teams, :homecourt, foreign_key: { to_table: :locations }, default: 0
    Team.create(id: 0, name: I18n.t("team.single"))
 end
end

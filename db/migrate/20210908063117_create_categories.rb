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
class CreateCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :sex
      t.integer :min_years
      t.integer :max_years

      t.timestamps
    end
    cname = I18n.t("scope.none")
    ActiveRecord::Base.connection.execute("INSERT INTO categories (id, name, sex, min_years, max_years, created_at, updated_at) values (0,'#{cname}', 'mixed', 5, 99,'2021-09-13 08:12','2021-09-13 08:12')")
  end
end

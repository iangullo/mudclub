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
class AddUserToPerson < ActiveRecord::Migration[6.1]
  def change
    add_reference :people, :user, null: false, foreign_key: true, default: 0
    u_id = User.find_by(email: 'admin@mudclub.org')&.id.to_i
    p_id = Person.find_by(email: 'admin@mudclub.org')&.id.to_i
    ActiveRecord::Base.connection.execute("UPDATE people SET user_id=#{u_id} WHERE id=#{p_id}")
  end
end

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
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
s_date = Date.today
s_year = s_date.year - (s_date.month < 7 ? 1 : 0)
e_year = s_year + 1
e_date = Date.new(e_year,6,30).to_s
s_date = Date.new(s_year,9,1).to_s
season = Season.create(start_date: s_date, end_date: e_date)
Location.create(name: "Homecourt", practice_court: false)
Location.create(name: "Indoor gym",practice_court: true)
Location.create(name: "Outdoor court", practice_court: true)
Location.real.each { |location| season.locations << location }
sport = Sport.first
Division.create(name: "Local", sport:)
Division.create(name: "Regional", sport:)
Division.create(name: "National", sport:)
Division.create(name: "Semi-pro", sport:)
Category.create(age_group: "Senior", sex: "female", min_years: 15, max_years: 99, rules: 0, sport:)
Category.create(age_group: "Senior", sex: "male", min_years: 15, max_years: 99, rules: 0, sport:)
Category.create(age_group: "U18", sex: "female", min_years: 15, max_years: 17, rules: 0, sport:)
Category.create(age_group: "U18", sex: "male", min_years: 15, max_years: 17, rules: 0, sport:)
Category.create(age_group: "U16", sex: "female", min_years: 13, max_years: 15, rules: 0, sport:)
Category.create(age_group: "U16", sex: "male", min_years: 13, max_years: 15, rules: 0, sport:)
Category.create(age_group: "U14", sex: "female", min_years: 11, max_years: 13, rules: 1, sport:)
Category.create(age_group: "U14", sex: "male", min_years: 11, max_years: 13, rules: 1, sport:)
Category.create(age_group: "U12", sex: "female", min_years: 9, max_years: 11, rules: 2, sport:)
Category.create(age_group: "U12", sex: "male", min_years: 9, max_years: 11, rules: 2, sport:)
Category.create(age_group: "U12", sex: "mixed", min_years: 9, max_years: 11, rules: 2, sport:)
Category.create(age_group: "U10", sex: "female", min_years: 6, max_years: 9, rules: 1, sport:)
Category.create(age_group: "U10", sex: "male", min_years: 6, max_years: 9, rules: 1, sport:)
Category.create(age_group: "U10", sex: "mixed", min_years: 6, max_years: 9, rules: 1, sport:)
Category.create(age_group: "U8", sex: "mixed", min_years: 5, max_years: 7, rules: 1, sport:)
Team.create(name: "U18 male", season_id: 1, category_id: 4, division_id: 2, homecourt_id: 1, sport_id: sport.id)
Team.create(name: "U18 female", season_id: 1, category_id: 4, division_id: 2, homecourt_id: 1, sport_id: sport.id)
Team.create(name: "U16 female", season_id: 1, category_id: 5, division_id: 2, homecourt_id: 1, sport_id: sport.id)
Team.create(name: "U16 male", season_id: 1, category_id: 6, division_id: 2, homecourt_id: 1, sport_id: sport.id)
Team.create(name: "U14 female", season_id: 1, category_id: 7, division_id: 2, homecourt_id: 1, sport_id: sport.id)
Team.create(name: "U14 male", season_id: 1, category_id: 8, division_id: 2, homecourt_id: 2, sport_id: sport.id)
Team.create(name: "U12 male", season_id: 1, category_id: 9, division_id: 1, homecourt_id: 1, sport_id: sport.id)
Team.create(name: "U12 female", season_id: 1, category_id: 10, division_id: 1, homecourt_id: 1, sport_id: sport.id)
Team.create(name: "U10 mixed", season_id: 1, category_id: 14, division_id: 1, homecourt_id: 1, sport_id: sport.id)
Team.create(name: "Baby Basket", season_id: 1, category_id: 15, division_id: 1, homecourt_id: 1, sport_id: sport.id)
Team.real.each { |team| season.teams << team }
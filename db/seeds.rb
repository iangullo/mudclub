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
e_year = s_date.year + (s_date.month > 6 ? 0 : 1)
e_date = Date.new(e_year,6,30).to_s
s_date = Date.new(s_year,9,1).to_s
season = Season.create(start_date: s_date, end_date: e_date)
Location.create(name: "Homecourt", practice_court: false)
Location.create(name: "Indoor gym",practice_court: true)
Location.create(name: "Outdoor court", practice_court: true)
Location.real.each { |location| season.locations << location }
Division.create(name: "Local")
Division.create(name: "Regional")
Division.create(name: "National")
Division.create(name: "Semi-pro")
=begin	# not sure I need to create any of these from scratch
Kind.create(name: "1x0")
Kind.create(name: "1x1")
Kind.create(name: "1x1+1")
Kind.create(name: "2x0")
Kind.create(name: "2x1")
Kind.create(name: "2x2")
Kind.create(name: "2x2+2")
Kind.create(name: "3x0")
Kind.create(name: "3x2")
Kind.create(name: "3x3")
Kind.create(name: "4x0")
Kind.create(name: "4x4")
Kind.create(name: "5x0")
Kind.create(name: "5x5")
Kind.create(name: "Físico")
Kind.create(name: "Descanso")
Kind.create(name: "Jugada")
Kind.create(name: "Defensa")
Kind.create(name: "Sistema")
Skill.create(concept: "Velocidad")
Skill.create(concept: "Salto")
Skill.create(concept: "Resistencia")
Skill.create(concept: "Fuerza")
Skill.create(concept: "Bote")
Skill.create(concept: "Pase")
Skill.create(concept: "Tiro")
Skill.create(concept: "Finalización")
Skill.create(concept: "Defensa")
Skill.create(concept: "Rebote")
Skill.create(concept: "M-a-M")
Skill.create(concept: "B.Ind.")
Skill.create(concept: "B.Dir.")
Skill.create(concept: "B.Ciego")
Skill.create(concept: "Cambio Direc.")
Skill.create(concept: "Cambio Ritmo")
=end
Category.create(age_group: "Senior", sex: "Fem.", min_years: 15, max_years: 99, rules: 0)
Category.create(age_group: "Senior", sex: "Masc.", min_years: 15, max_years: 99, rules: 0)
Category.create(age_group: "U18", sex: "Fem.", min_years: 15, max_years: 17, rules: 0)
Category.create(age_group: "U18", sex: "Masc.", min_years: 15, max_years: 17, rules: 0)
Category.create(age_group: "U16", sex: "Fem.", min_years: 13, max_years: 15, rules: 0)
Category.create(age_group: "U16", sex: "Masc.", min_years: 13, max_years: 15, rules: 0)
Category.create(age_group: "U14", sex: "Fem.", min_years: 11, max_years: 13, rules: 1)
Category.create(age_group: "U14", sex: "Masc.", min_years: 11, max_years: 13, rules: 1)
Category.create(age_group: "U12", sex: "Fem.", min_years: 9, max_years: 11, rules: 2)
Category.create(age_group: "U12", sex: "Masc.", min_years: 9, max_years: 11, rules: 2)
Category.create(age_group: "U12", sex: "Mixto", min_years: 9, max_years: 11, rules: 2)
Category.create(age_group: "U10", sex: "Fem.", min_years: 6, max_years: 9, rules: 1)
Category.create(age_group: "U10", sex: "Masc.", min_years: 6, max_years: 9, rules: 1)
Category.create(age_group: "U10", sex: "Mixto", min_years: 6, max_years: 9, rules: 1)
Category.create(age_group: "U8", sex: "Mixto", min_years: 5, max_years: 7, rules: 1)
Team.create(name: "U18 Masc.", season_id: 1, category_id: 4, division_id: 2, homecourt_id: 1, rules: 0)
Team.create(name: "U18 Fem.", season_id: 1, category_id: 4, division_id: 2, homecourt_id: 1, rules: 0)
Team.create(name: "U16 Fem.", season_id: 1, category_id: 5, division_id: 2, homecourt_id: 1, rules: 0)
Team.create(name: "U16 Masc.", season_id: 1, category_id: 6, division_id: 2, homecourt_id: 1, rules: 0)
Team.create(name: "U14 Fem.", season_id: 1, category_id: 7, division_id: 2, homecourt_id: 1, rules: 1)
Team.create(name: "U14 Masc.", season_id: 1, category_id: 8, division_id: 2, homecourt_id: 2, rules: 1)
Team.create(name: "U12 Masc.", season_id: 1, category_id: 9, division_id: 1, homecourt_id: 1, rules: 2)
Team.create(name: "U12 Fem.", season_id: 1, category_id: 10, division_id: 1, homecourt_id: 1, rules: 2)
Team.create(name: "U10 Mixed", season_id: 1, category_id: 14, division_id: 1, homecourt_id: 1, rules: 1)
Team.create(name: "Baby Basket", season_id: 1, category_id: 15, division_id: 1, homecourt_id: 1, rules: 1)
Team.real.each { |team| season.teams << team }

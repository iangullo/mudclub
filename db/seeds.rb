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
Season.create(start_date: "2022-09-01", end_date: "2023-06-30")
Location.create(name: "Pab. Habitual", practice_court: false)
Location.create(name: "Pista Entr. 1",practice_court: true)
Location.create(name: "Pista Entr. 2", practice_court: true)
Location.create(name: "Pab. Secundario", practice_court: false)
Division.create(name: "Local")
Division.create(name: "Comarcal")
Division.create(name: "Provincial")
Division.create(name: "Autonómica")
Division.create(name: "Nacional")
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
Category.create(age_group: "Senior", sex: "Fem.", min_years: 15, max_years: 99, rules: 0)
Category.create(age_group: "Senior", sex: "Masc.", min_years: 15, max_years: 99, rules: 0)
Category.create(age_group: "Junior", sex: "Fem.", min_years: 15, max_years: 17, rules: 0)
Category.create(age_group: "Junior", sex: "Masc.", min_years: 15, max_years: 17, rules: 0)
Category.create(age_group: "Cadete", sex: "Fem.", min_years: 13, max_years: 15, rules: 0)
Category.create(age_group: "Cadete", sex: "Masc.", min_years: 13, max_years: 15, rules: 0)
Category.create(age_group: "Infantil", sex: "Fem.", min_years: 11, max_years: 13, rules: 1)
Category.create(age_group: "Infantil", sex: "Masc.", min_years: 11, max_years: 13, rules: 1)
Category.create(age_group: "Alevín", sex: "Fem.", min_years: 9, max_years: 11, rules: 2)
Category.create(age_group: "Alevín", sex: "Masc.", min_years: 9, max_years: 11, rules: 2)
Category.create(age_group: "Alevín", sex: "Mixto", min_years: 9, max_years: 11, rules: 2)
Category.create(age_group: "Benjamín", sex: "Fem.", min_years: 6, max_years: 9, rules: 1)
Category.create(age_group: "Benjamín", sex: "Masc.", min_years: 6, max_years: 9, rules: 1)
Category.create(age_group: "Benjamín", sex: "Mixto", min_years: 6, max_years: 9, rules: 1)
Category.create(age_group: "Baby Basket", sex: "Mixto", min_years: 5, max_years: 7, rules: 1)
Team.create(name: "Senior Fem.", season_id: 1, category_id: 1, division_id: 3, homecourt_id: 1, rules: 0)
Team.create(name: "Senior Masc,", season_id: 1, category_id: 2, division_id: 3, homecourt_id: 1, rules: 0)
Team.create(name: "Junior Masc.", season_id: 1, category_id: 4, division_id: 3, homecourt_id: 1, rules: 0)
Team.create(name: "Cadete Fem.", season_id: 1, category_id: 5, division_id: 3, homecourt_id: 1, rules: 0)
Team.create(name: "Cadete Masc.", season_id: 1, category_id: 6, division_id: 3, homecourt_id: 1, rules: 0)
Team.create(name: "Infantil Fem.", season_id: 1, category_id: 7, division_id: 3, homecourt_id: 1, rules: 1)
Team.create(name: "Infantil Masc.", season_id: 1, category_id: 8, division_id: 2, homecourt_id: 2, rules: 1)
Team.create(name: "Alevín Masc.", season_id: 1, category_id: 9, division_id: 3, homecourt_id: 1, rules: 2)
Team.create(name: "Alevín Fem.", season_id: 1, category_id: 10, division_id: 3, homecourt_id: 1, rules: 2)
Team.create(name: "Benjamín", season_id: 1, category_id: 14, division_id: 1, homecourt_id: 1, rules: 1)
Team.create(name: "Baby Basket", season_id: 1, category_id: 15, division_id: 1, homecourt_id: 1, rules: 1)
Season.last.locations << Location.find(1)
Season.last.locations << Location.find(2)
Season.last.locations << Location.find(3)
Season.last.locations << Location.find(4)

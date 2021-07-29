# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Person.create(id: 0, name: "Nueva", birthday: "2021-07-01", player_id: 0, coach_id: 0, female: false)
Player.create(id: 0, number: 0, person_id: 0, active: false)
Coach.create(id: 0, person_id: 0, active: false)
Category.create(id: 0, name: "Sin Categoría", min_years: 0, max_years: 99, sex: "Mixto")
Division.create(id: 0, name: "Niguna")
Season.create(id: 0, name: "Niguna")
Team.create(id: 0, name: "Sin equipo", category_id: 0, division_id: 0, season_id: 0, female: false)
TrainingSlot.create(id: 0, team_id: 0, location_id: 0, season_id: 0, wday: 0, start: "16:00:00", duration: 90)

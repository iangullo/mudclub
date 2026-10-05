json.extract! registration, :id, :club_id, :requested_team_id, :candidate_name, :candidate_surname, :candidate_birthday, :kind, :created_at, :updated_at
json.url club_registration_url(club_id, registration, format: :json)

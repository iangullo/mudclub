json.extract! assignment, :id, :club_id, :membership_id, :kind, :created_at, :updated_at
json.url club_assignment_url(club_id, assignment, format: :json)

json.extract! member, :id, :club_id, :person_id, :kind, :created_at, :updated_at
json.url club_member_url(club_id, member, format: :json)

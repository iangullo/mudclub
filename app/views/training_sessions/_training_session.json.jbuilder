json.extract! training_session, :id, :team_id, :date, :training_slot_id, :created_at, :updated_at
json.url training_session_url(training_session, format: :json)

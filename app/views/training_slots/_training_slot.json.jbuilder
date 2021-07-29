json.extract! training_slot, :id, :season_id, :location_id, :wday, :start, :duration, :created_at, :updated_at
json.url training_slot_url(training_slot, format: :json)

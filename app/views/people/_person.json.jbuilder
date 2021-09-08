json.extract! person, :id, :nick, :name, :surname, :birthday, :female, :created_at, :updated_at
json.url person_url(person, format: :json)

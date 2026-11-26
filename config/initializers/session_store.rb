# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
	key: Rails.env.production? ? "__Host-sid" : "_sid",
	secure: Rails.env.production?,
	httponly: true,
	same_site: :lax

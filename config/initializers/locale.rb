# config/initializers/locale.rb

# -----------------------------------------------------------------------------
# Internationalization (I18n)
# -----------------------------------------------------------------------------
#
# Locale files are organised by bounded context:
#
#   config/locales/
#     core/
#     people/
#     participation/
#     ...
#
# Sport-specific locale files live together with the sport implementation:
#
#   app/sports/
#     basketball/
#       locales/
#         en.yml
#         es.yml
#
# Rails recursively loads every *.yml and *.rb locale file.
# -----------------------------------------------------------------------------

I18n.load_path += Dir[
	Rails.root.join("config", "locales", "**", "*.{rb,yml}"),
	Rails.root.join("app", "sports", "*", "locales", "**", "*.{rb,yml}")
]

#
# Supported languages
#
I18n.available_locales = %i[
	es
	en
]

#
# Default application language
#
I18n.default_locale = :es

#
# Raise an exception when a translation is missing (development/test only)
#
# I18n.raise_on_missing_translations = true

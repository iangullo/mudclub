# test/mailers/previews/registration_mailer_preview.rb
class RegistrationMailerPreview < ActionMailer::Preview
	def approved
		RegistrationMailer.with(
			recipient:  "parent@example.com",
			requester:  "Marta García",
			candidate:  "Alicia García",
			club:       "MudClub",
			team:       "Equipo A",
			membership: "Jugadora"
		).approved
	end

	def approved_without_team
		RegistrationMailer.with(
			recipient:  "parent@example.com",
			requester:  "Marta García",
			candidate:  "Alicia García",
			club:       "MudClub",
			membership: "Jugadora"
		).approved
	end

	def rejected
		RegistrationMailer.with(
			recipient: "parent@example.com",
			requester: "Marta García",
			candidate: "Alicia García",
			club:      "MudClub",
			reason:    "Falta el DNI del tutor legal"
		).rejected
	end
end

# app/mailers/development_mail_interceptor.rb
class DevelopmentMailInterceptor
	def self.delivering_email(message)
		message.to = ENV.fetch("STAGING_OVERRIDE_EMAIL", "dev@localhost")
		message.subject = "[STAGING] #{message.subject}"
	end
end

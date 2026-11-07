# config/initializers/mail_delivery_retries.rb
Rails.application.config.after_initialize do
	ActionMailer::MailDeliveryJob.retry_on(
		Net::SMTPServerBusy, wait: :polynomially_longer, attempts: 5
	)
	ActionMailer::MailDeliveryJob.retry_on(
		Net::OpenTimeout, Net::ReadTimeout, wait: 30.seconds, attempts: 3
	)
	ActionMailer::MailDeliveryJob.retry_on(
		Errno::ECONNREFUSED, SocketError, wait: 30.seconds, attempts: 3
	)
	ActionMailer::MailDeliveryJob.discard_on(
		Net::SMTPFatalError     # 5xx from the relay — retrying won't help
	)
end

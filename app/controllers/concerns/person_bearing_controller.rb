# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
# Shared transactional persistence, duplicate-merge handling, and status
# transitions for controllers managing PersonBearing records
# (Membership, Assignment, User).
module PersonBearingController
	extend ActiveSupport::Concern

	private

		# Executes transactional rebuild/merge + save for PersonBearing records.
		# Yields the surviving record inside the transaction before `save` (e.g., to set
		# defaults or enforce domain guards), and invokes `on_success` / `on_failure`.
		def save_with_person_merge(record, params, on_success:, on_failure:, &before_save)
			result   = nil
			saved    = false
			modified = false

			record.class.transaction do
				result = rebuild_or_merge_person(record, params)
				next unless result[:status] == :ok

				record   = result[:record] if result[:record]
				modified = record.modified?

				if before_save
					raise ActiveRecord::Rollback unless before_save.call(record)
				end

				if !modified && record.persisted?
					saved = true
				elsif record.save
					saved = true
				else
					raise ActiveRecord::Rollback
				end
			rescue ActiveRecord::RecordInvalid
				raise ActiveRecord::Rollback
			end

			case result[:status]
			when :ok
				saved ? on_success.call(record, modified) : on_failure.call(record, result)
			when :offer_merge
				respond_to do |format|
					handle_object_merge(format, record, result[:candidates], params)
				end
			else
				on_failure.call(record, result)
			end
		end

		# Unified GDPR/LOPD anonymization flow for Membership and User controllers
		def handle_anonymize(record, redirect_url:, failure_url: path_for(record), require_terminated: false, &after_anonymize)
			if require_terminated && !record.terminated?
				return redirect_to failure_url, alert: record.msg(:must_terminate)
			end

			success =
				if record.respond_to?(:archive_and_anonymize!)
					record.archive_and_anonymize!
				else
					record.anonymize!
					record.reload.anonymized_at.present?
				end

			if success
				after_anonymize&.call(record)
				notice = helpers.flash_message(record.msg(:anonymized), "success")
				redirect_to redirect_url, status: :see_other, notice:
			else
				redirect_to failure_url, alert: record.msg(:anonymize_fail)
			end
		end

		# Unified status-only transition response for Participatory models (Membership, Assignment)
		def handle_status_only_update(record, redirect_url:)
			respond_to do |format|
				if perform_status_change(record, status_value_for(record))
					notice = helpers.flash_message(record.msg(:updated), :success)
					format.html         { redirect_to redirect_url, notice:, status: :see_other, turbo_action: "replace" }
					format.turbo_stream { redirect_to redirect_url, notice:, status: :see_other, turbo_action: "replace" }
					format.json         { render :show, status: :ok, location: record }
				else
					message = record.errors.full_messages.to_sentence.presence || record.msg(:status_fail)
					notice  = helpers.flash_message(message, :error)
					format.html         { redirect_to redirect_url, notice: }
					format.turbo_stream { redirect_to redirect_url, notice: }
					format.json         { render json: record.errors, status: :unprocessable_entity }
				end
			end
		end

		# Unified termination flow for Participatory records (Membership, Assignment)
		def handle_terminate(record, redirect_url:)
			if record.terminate!
				redirect_to redirect_url, notice: record.class.msg(:terminated)
			else
				redirect_back fallback_location: redirect_url, alert: record.class.msg(:cannot_terminate)
			end
		end

		def log_person_bearing_errors(record)
			Rails.logger.debug record.errors.full_messages
			return unless record.person

			Rails.logger.debug record.person.errors.full_messages
			record.person.relationships.each do |r|
				Rails.logger.debug r.errors.full_messages
				Rails.logger.debug r.related_person.errors.full_messages if r.related_person
			end
		end

		def respond_saved(location:, notice:, template: :show, status: :ok, turbo_status: nil, data: nil)
			respond_to do |format|
				html_opts  = { notice:, data: }.compact
				turbo_opts = { notice:, status: turbo_status, data: }.compact

				format.html         { redirect_to location, **html_opts }
				format.turbo_stream { redirect_to location, **turbo_opts }
				format.json         { render template, status:, location: }
			end
		end
end

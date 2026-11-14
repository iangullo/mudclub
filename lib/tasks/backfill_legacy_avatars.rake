# lib/tasks/mudclub/backfill_legacy_avatars.rake
require "set"
require "stringio"

namespace :mudclub do
	desc "Copy avatars from legacy Player/Coach to Membership/Assignment where missing"
	task backfill_legacy_avatars: :environment do
		dry_run = ENV.fetch("DRY_RUN", "true") == "true"
		verbose = ENV.fetch("VERBOSE", "false") == "true"
		stats   = Hash.new(0)

		already_set             = { memberships: {}, assignments: {} }
		attached_assignment_ids = Set.new

		log = ->(msg) { puts msg if verbose || dry_run }

		attach_if_missing = lambda do |source, target|
			return :no_source   unless source.avatar.attached?
			return :already_set if target.avatar.attached?

			blob = source.avatar.blob
			if dry_run
				log.call("  [DRY] #{source.class.name}##{source.id} → #{target.class.name}##{target.id}")
			else
				target.avatar.attach(
					io:           StringIO.new(blob.download),
					filename:     blob.filename.to_s,
					content_type: blob.content_type
				)
				log.call("  [OK]  #{source.class.name}##{source.id} → #{target.class.name}##{target.id}")
			end
			:attached
		end

		# ====================================================================
		# PASS 1 — Legacy Player/Coach → Membership / Assignment
		# ====================================================================
		process_legacy = lambda do |legacy, membership_kind|
			begin
				unless legacy.avatar.attached?
					stats[:skipped_no_source_avatar] += 1
					return
				end

				person = Person.find_by(id: legacy.person_id)
				unless person
					stats[:skipped_no_person] += 1
					return
				end
				canonical = person.canonical
				unless canonical&.id.to_i > 0
					stats[:skipped_no_canonical_person] += 1
					return
				end

				found = false
				Membership.of_kind(membership_kind)
									.where(person_id: canonical.id)
									.find_each do |membership|
					found = true
					stats[:memberships_scanned] += 1

					case attach_if_missing.call(legacy, membership)
					when :attached
						stats[:memberships_attached] += 1
					when :already_set
						stats[:memberships_already_set] += 1
						already_set[:memberships][membership.id] ||=
							"Membership##{membership.id} (person=#{canonical}, kind=#{membership.kind}, club_id=#{membership.club_id})"
					end

					membership.assignments.current.find_each do |assignment|
						stats[:assignments_scanned_legacy] += 1
						case attach_if_missing.call(legacy, assignment)
						when :attached
							stats[:assignments_attached_legacy] += 1
							attached_assignment_ids << assignment.id
						when :already_set
							stats[:assignments_already_set_legacy] += 1
							already_set[:assignments][assignment.id] ||=
								"Assignment##{assignment.id} (kind=#{assignment.kind}, team_id=#{assignment.team_id})"
						end
					end
				end

				stats[:skipped_no_membership] += 1 unless found
			rescue => e
				stats[:errors] += 1
				warn "ERROR #{legacy.class.name}##{legacy.id}: #{e.class} — #{e.message}"
				warn e.backtrace.first(5).join("\n") if verbose
			end
		end

		# ====================================================================
		# PASS 2 — Membership → its current Assignments
		# ====================================================================
		process_membership = lambda do |membership|
			begin
				return unless membership.avatar.attached?

				stats[:memberships_scanned_membership] += 1

				membership.assignments.current.find_each do |assignment|
					next if attached_assignment_ids.include?(assignment.id)
					stats[:assignments_scanned_membership] += 1

					case attach_if_missing.call(membership, assignment)
					when :attached
						stats[:assignments_attached_membership] += 1
						attached_assignment_ids << assignment.id
					when :already_set
						stats[:assignments_already_set_membership] += 1
						already_set[:assignments][assignment.id] ||=
							"Assignment##{assignment.id} (kind=#{assignment.kind}, team_id=#{assignment.team_id})"
					end
				end
			rescue => e
				stats[:errors] += 1
				warn "ERROR Membership##{membership.id}: #{e.class} — #{e.message}"
				warn e.backtrace.first(5).join("\n") if verbose
			end
		end

		puts "Backfill legacy avatars (dry_run=#{dry_run})"

		puts "\n[Pass 1] Legacy Player/Coach → Membership / Assignment"
		Player.real.find_each { |p| process_legacy.call(p, :athlete) }
		Coach.real.find_each  { |c| process_legacy.call(c, :coach)  }

		puts "\n[Pass 2] Membership → current Assignments"

		# record_id in active_storage_attachments is varchar; pluck materialises
		# UUID *strings* which AR then casts on bind for the uuid column. Using
		# the attachment query as a subquery here would fail on PostgreSQL with
		# "operator does not exist: uuid = character varying".
		membership_ids = ActiveStorage::Attachment
											.where(record_type: "Membership", name: "avatar")
											.pluck(:record_id)

		Membership.where(id: membership_ids)
							.includes(:avatar_attachment)   # avoids N+1 on avatar.attached?
							.find_each { |m| process_membership.call(m) }

		puts "\nSummary:"
		stats.sort_by { |k, _| k.to_s }.each { |k, v| puts "  #{k}: #{v}" }

		unless already_set[:memberships].empty? && already_set[:assignments].empty?
			puts "\nAlready had an avatar (skipped, not overwritten):"

			puts "  Memberships (#{already_set[:memberships].size}):"
			already_set[:memberships].each_value { |line| puts "    #{line}" }

			puts "  Assignments (#{already_set[:assignments].size}):"
			already_set[:assignments].each_value { |line| puts "    #{line}" }
		end
	end
end

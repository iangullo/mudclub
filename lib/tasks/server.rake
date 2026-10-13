# lib/tasks/server.rake

require "shellwords"

namespace :server do
	desc "Make a backup of the MudClub server filesystem"
	task backup: :environment do
		print_heading("backup", "#{Rails.root}/ => #{backup_dir}/")
		rsync(
			"#{Rails.root}/",           # trailing slash: copy contents
			"#{backup_dir}/",           # trailing slash: into existing dir
			exclude: backup_excludes
		)
	end

	desc "Restore server filesystem from the latest backup"
	task restore: :environment do
		print_heading("restore", "#{backup_dir}/ => #{Rails.root}/")
		rsync(
			"#{backup_dir}/",
			"#{Rails.root}/",
			exclude: backup_excludes
		)
	end

	desc "Show server status"
	task status: :environment do
		puts "MudClub server"
		puts "  status:   #{server_status}"
		puts "  version:  #{server_version}"
		puts "  hostname: #{server_host}"
		puts "  hostpath: #{Rails.root}"
		puts "  backups:  #{backup_dir}/"
	end

	desc "Purge orphaned ActiveStorage blobs (unattached for over a week)"
	task purge_blobs: :environment do
		cutoff = 1.week.ago
		queued = 0

		ActiveStorage::Blob
			.unattached
			.where("created_at < ?", cutoff)
			.find_each do |blob|
				next unless blob.attachments.empty?   # re-check: another request may have just attached it

				blob.purge_later
				queued += 1
			end

		puts "Queued #{queued} orphaned blob(s) for purging"
	end
end

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
# These are top-level methods, not namespaced. Rake's namespace block doesn't
# reliably scope method visibility, so pretending otherwise is worse than
# accepting they're global. Names are prefixed to avoid collisions.

def server_host
	@server_host ||= `hostname`.to_s.strip
end

def server_version
	@server_version ||= begin
		file = Rails.root.join("VERSION")
		file.exist? ? file.read.strip : "unknown"
	rescue StandardError
		"unknown"
	end
end

def backup_dir
	Rails.root.join("backup").to_s
end

def backup_excludes
	%w[
		backup/
		node_modules/
		tmp/
		log/
		.bash_history
		.git/
		storage/*.sqlite3
	]
end

def server_status
	pidfile = Rails.root.join("tmp", "pids", "server.pid")
	return "STOPPED" unless pidfile.exist?

	pid = pidfile.read.to_i
	Process.getpgid(pid)
	"RUNNING (#{pid})"
rescue Errno::ESRCH
	"STALE PID FILE (#{pid})"   # file present, process gone
rescue StandardError => e
	"UNKNOWN (#{e.class})"
end

def print_heading(label, paths)
	puts "MudClub server: #{label} (#{paths})"
end

def rsync(src, dst, exclude: [])
	FileUtils.mkdir_p(dst)

	cmd = [ "rsync", "-aPv" ]
	exclude.each { |pattern| cmd += [ "--exclude", pattern ] }
	cmd += [ src, dst ]

	puts "→ #{cmd.shelljoin}"
	abort "rsync failed" unless system(*cmd)
end

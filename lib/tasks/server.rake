namespace :server do
  SERVER_HOST = `hostname`
  SERVER_VER  = `cat VERSION`
  BACKUP_DIR  = "#{Rails.root}/backup/"
  SERVER_DIR  = "#{Rails.root}/"
  desc "Makes a backup of the MudClub server filesystem"
  task :backup do
    puts "MudClub server: backup (#{SERVER_DIR} => #{BACKUP_DIR})"
    system "rsync -aPv #{SERVER_DIR} #{BACKUP_DIR} --exclude='backup' --exclude='node_modules' --exclude='tmp/*'"
  end

  task :status do
    puts "MudClub server"
    puts "  status:   #{server_status}"
    puts "  version:  #{SERVER_VER}"
    puts "  hostname: #{SERVER_HOST}"
    puts "  hostpath: #{SERVER_DIR}"
    puts "  backups:  #{BACKUP_DIR}"
  end

  task :restore do
  end

  private
    def server_status
      pidfile = File.join(Rails.root, "tmp", "pids", "server.pid")
      pid     = File.read(pidfile).to_i
      return "RUNNING (#{pid})"
      begin
        Process.getpgid pid
      rescue Errno::ESRCH
        return "STOPPED"
      end
    end
end

namespace :server do
  SERVER_HOST = `hostname`
  SERVER_VER  = `cat VERSION`
  BACKUP_DIR  = "#{Rails.root}/backup/"
  SERVER_DIR  = "#{Rails.root}/"
  EXCL_FILES  = "--exclude='backup' --exclude='node_modules' --exclude='tmp/*' --exclude='log/*' --exclude='.bash_history'"
  desc "Makes a backup of the MudClub server filesystem"
  task :backup do
    puts "MudClub server: backup (#{SERVER_DIR} => #{BACKUP_DIR})"
    system "rsync -aPv #{SERVER_DIR} #{BACKUP_DIR} #{EXCL_FILES}"
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
    puts "MudClub server: restore (#{BACKUP_DIR} => #{SERVER_DIR})"
    system "rsync -aPv #{BACKUP_DIR} #{SERVER_DIR}  #{EXCL_FILES}"
  end

  private
    def server_status
      begin
        Process.getpgid pid
        pidfile = File.join(Rails.root, "tmp", "pids", "server.pid")
        pid     = File.read(pidfile).to_i
        return "RUNNING (#{pid})"
      rescue Errno::ESRCH
        return "STOPPED"
      end
    end
end

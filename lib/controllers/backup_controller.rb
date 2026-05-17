# frozen_string_literal: true

require "fileutils"
require "securerandom"
require "tempfile"

class BackupController < Sinatra::Base
  # Holds Tempfile objects between the POST that creates them and the
  # follow-up download. Without a strong reference, Tempfile's finalizer
  # could delete the dump file on the next GC — turning the redirected
  # download into a 404 race.
  PENDING_DUMPS = {} # rubocop:disable Style/MutableConstant
  PENDING_DUMPS_LOCK = Mutex.new

  post "/" do
    tempfile = create_sql_tempfile("dump")

    dump_command = [
      "pg_dump",
      "--format=plain",
      "#{ENV.fetch('DATABASE_URL')}",
    ]

    system(*dump_command, out: tempfile.path, exception: true)

    token = SecureRandom.urlsafe_base64(16)
    PENDING_DUMPS_LOCK.synchronize { PENDING_DUMPS[token] = tempfile }

    # 307 preserves the original POST method on redirect (per RFC 7231).
    redirect url("/download/#{token}"), 307
  end

  post "/download/:token" do
    tempfile = PENDING_DUMPS_LOCK.synchronize do
      PENDING_DUMPS.delete(params.fetch("token"))
    end
    halt 404, "Backup not found" unless tempfile

    send_file tempfile.path, type: "text/plain"
  end

  helpers do
    def backup_tmpdir
      File.join(Dir.tmpdir, "wiki_backup")
    end

    def create_sql_tempfile(filename)
      tmpdir = FileUtils.mkdir_p(backup_tmpdir).first

      Tempfile.new([filename, ".sql"], tmpdir)
    end
  end
end

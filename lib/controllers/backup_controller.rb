# frozen_string_literal: true

require "base64"
require "fileutils"
require "securerandom"

class BackupController < Sinatra::Base
  STALE_DUMP_AGE = 3600 # seconds

  post "/" do
    sweep_stale_dumps
    dump_path    = create_dump_path
    rel_path     = dump_path.split(backup_tmpdir).last
    encoded_path = Base64.urlsafe_encode64(rel_path)

    dump_command = [
      "pg_dump",
      "--format=plain",
      "#{ENV.fetch('DATABASE_URL')}",
    ]

    system(*dump_command, out: dump_path, exception: true)

    # From https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/307
    #
    # > 307 guarantees that the method and the body will not be changed when the
    # > redirected request is made
    #
    # curl respects the original method even for 303 redirects
    # despite the man page stating the opposite (curl 7.84.0)
    # rack-test only preseerve original method for 307 redirects
    #
    redirect url("/download/#{encoded_path}"), 307
  end

  post "/download/:encoded_path" do
    rel_path  = Base64.urlsafe_decode64(params.fetch("encoded_path"))
    dump_path = resolve_within_backup_dir(rel_path)
    halt 404 unless dump_path

    send_file dump_path, type: "text/plain"
  end

  helpers do
    def backup_tmpdir
      File.join(Dir.tmpdir, "wiki_backup")
    end

    # Resolve symlinks and `..`, then require the result to stay inside the backup dir.
    def resolve_within_backup_dir(rel_path)
      root = File.realpath(backup_tmpdir)
      path = File.realpath(File.join(root, rel_path))
      path if path.start_with?(root + File::SEPARATOR)
    rescue Errno::ENOENT
      nil
    end

    # Own the path outright; Tempfile's finalizer would delete it before download.
    def create_dump_path
      FileUtils.mkdir_p(backup_tmpdir)

      File.join(backup_tmpdir, "dump-#{SecureRandom.uuid}.sql")
    end

    # Replaces Tempfile's finalizer: drop dumps left behind by earlier backups.
    def sweep_stale_dumps
      cutoff = Time.now - STALE_DUMP_AGE

      Dir.glob(File.join(backup_tmpdir, "dump-*.sql")).each do |path|
        File.delete(path) if File.mtime(path) < cutoff
      rescue Errno::ENOENT
        nil
      end
    end
  end
end

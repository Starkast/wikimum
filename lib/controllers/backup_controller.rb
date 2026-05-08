# frozen_string_literal: true

require "base64"
require "fileutils"
require "sqlite3"
require "tempfile"

class BackupController < Sinatra::Base
  post "/" do
    backup_path  = create_backup_tempfile.path
    rel_path     = backup_path.split(backup_tmpdir).last
    encoded_path = Base64.urlsafe_encode64(rel_path)

    online_backup(DB.opts.fetch(:database), backup_path)

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
    rel_path    = Base64.urlsafe_decode64(params.fetch("encoded_path"))
    backup_path = File.join(backup_tmpdir, rel_path)

    send_file backup_path, type: "application/vnd.sqlite3"
  end

  helpers do
    def backup_tmpdir
      File.join(Dir.tmpdir, "wiki_backup")
    end

    def create_backup_tempfile
      tmpdir = FileUtils.mkdir_p(backup_tmpdir).first

      Tempfile.new(["dump", ".sqlite3"], tmpdir)
    end

    def online_backup(source_path, target_path)
      source = SQLite3::Database.new(source_path)
      target = SQLite3::Database.new(target_path)
      backup = SQLite3::Backup.new(target, "main", source, "main")
      backup.step(-1)
    ensure
      backup&.finish
      target&.close
      source&.close
    end
  end
end

# frozen_string_literal: true

require "base64"

class BackupController < Sinatra::Base
  post "/" do
    dump_path    = create_tempfile("wiki_backup.sql").path
    encoded_path = Base64.urlsafe_encode64(dump_path)

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
    dump_path = Base64.urlsafe_decode64(params.fetch("encoded_path"))

    send_file dump_path, type: "text/plain"
  end

  helpers do
    def create_tempfile(filename)
      File.new(File.join(Dir.mktmpdir, filename), "w+")
    end
  end
end

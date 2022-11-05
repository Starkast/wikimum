# frozen_string_literal: true

require "dyno_metadata"

module AppMetadata
  module_function

  def release_version
    DynoMetadata.release_version
  end

  def commit
    DynoMetadata.commit
  end

  def short_commit
    DynoMetadata.short_commit
  end
end

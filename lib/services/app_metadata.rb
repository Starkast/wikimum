# frozen_string_literal: true

# The release being run, set by wikimum-deploy (see Starkast/ansible)
module AppMetadata
  module_function

  def release_version
    ENV.fetch("RELEASE_VERSION", "dev")
  end

  def commit
    ENV.fetch("RELEASE_COMMIT", "HEAD")
  end

  def short_commit
    commit[0, 7]
  end
end

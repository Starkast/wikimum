# frozen_string_literal: true

require "digest"
require "securerandom"

class BotCredential < Sequel::Model
  many_to_one :bot, class: :User
  many_to_one :page

  ENROLLMENT_TTL = 10 * 60

  dataset_module do
    def active
      where(revoked_on: nil)
    end
  end

  def self.issue(page:, owner:, name:)
    db.transaction do
      bot = User.create(login: name, owner: owner)
      token = SecureRandom.hex(32)
      credential = create(
        bot: bot,
        page: page,
        enrollment_digest: digest(token),
        enrollment_expires_on: Time.now + ENROLLMENT_TTL,
      )
      [credential, "wm_enroll_#{credential.id}_#{token}"]
    end
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def enrolled?
    !enrolled_on.nil?
  end

  def revoke!
    update(revoked_on: Time.now)
  end
end

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

  # Single use: the conditional update only succeeds for the first caller.
  def self.enroll(token)
    credential = find_by_token("wm_enroll", token, :enrollment_digest)
    return unless credential && credential.enrollment_expires_on > Time.now

    secret = SecureRandom.hex(32)
    claimed = where(id: credential.id, enrollment_digest: credential.enrollment_digest)
      .update(enrollment_digest: nil, secret_digest: digest(secret), enrolled_on: Time.now)
    return unless claimed == 1

    [credential.refresh, "wm_bot_#{credential.id}_#{secret}"]
  end

  def self.authenticate(token)
    find_by_token("wm_bot", token, :secret_digest)&.update(last_used_on: Time.now)
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.find_by_token(prefix, token, column)
    match = /\A#{prefix}_(\d+)_(\h{64})\z/.match(token.to_s)
    return unless match

    credential = active.first(id: match[1].to_i)
    stored = credential&.public_send(column)
    credential if stored && Rack::Utils.secure_compare(stored, digest(match[2]))
  end
  private_class_method :find_by_token

  def enrolled?
    !enrolled_on.nil?
  end

  def revoke!
    update(revoked_on: Time.now)
  end
end

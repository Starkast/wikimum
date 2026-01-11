# frozen_string_literal: true

class Upload < Sequel::Model
  many_to_one :page
  many_to_one :author, class: :User

  def before_create
    self.created_on = Time.now
  end

  def path
    "/#{page.slug}/uploads/#{id}/"
  end

  def markdown_reference
    if image?
      "![#{filename}](#{path})"
    else
      "[#{filename}](#{path})"
    end
  end

  def image?
    content_type&.start_with?("image/")
  end
end

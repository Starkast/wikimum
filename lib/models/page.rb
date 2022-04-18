# frozen_string_literal: true

class Page < Sequel::Model

  one_to_many :revisions
  many_to_one :author, class: :User

  SEARCH_IN_COLUMNS = %i(title content description).freeze

  dataset_module do
    def with_concealed_if(allowed_to_see_concealed)
      if allowed_to_see_concealed
        self
      else
        self.exclude(concealed: true)
      end
    end

    def search(query)
      terms = query.to_s.strip.split

      return self.where { false } if terms.empty?

      self.full_text_search(SEARCH_IN_COLUMNS, terms, rank: true)
    end
  end

  def before_create
    self.slug = Slug.slugify(self.title)
  end

  def before_save
    self.compiled_content = Markup.to_html(self.content)
    self.updated_on = Time.now
    self.title_char = Title.new(self.title).first_char
    self.sha1 = self.calculate_sha1
  end

  def revise!
    new_revision = Revision.new
    self.values.each do |key, value|
      next if %i(id concealed).include?(key)
      new_revision[key] = value
    end
    new_revision.page_id = self.id
    new_revision.save

    self.revision += 1
  end

  def calculate_sha1
    Digest::SHA1.hexdigest(self.to_hash.values.join)
  end
end

class Page < Sequel::Model

  one_to_many :revisions
  many_to_one :author, class: :User

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

  def self.search(query)
    terms = query.to_s.strip.split

    return [] if terms.empty?

    columns  = %i(title content description)

    self.dataset.full_text_search(columns, terms, rank: true).to_a
  end
end

class Page < Sequel::Model
  def before_create
    self.slug = Title.new(self.title).slug
  end

  def before_save
    self.compiled_content = Markup.to_html(self.content)
    self.updated_on = Time.now
    self.title_char = Title.new(self.title).first_char
  end

  def self.search(query)
    terms = query.to_s.strip.split

    return [] if terms.empty?

    columns  = [:title, :content, :description]
    patterns = terms.map {|t| "%#{t}%" }

    self.dataset.grep(columns, patterns, case_insensitive: true, all_patterns: true)
  end
end

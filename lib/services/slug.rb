require 'rack/utils'

class Slug

  REGEXP = /[^\d\w\sÅÄÖåäö:-]/i

  def self.slugify(string)
    slug(Rack::Utils.unescape(string))
  end

  def self.slug(string)
    string.gsub(REGEXP, '').gsub(' ', '_').downcase
  end
end

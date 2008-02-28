class Alias < ActiveRecord::Base
  belongs_to :page
  
  def to_s
    self.alias
  end
  
  def validate # and fix
    self.alias = self.alias.strip.to_shorthand

	  if self.alias.length < 1 or self.alias.length < 1
	    errors.add :alias, 'Några bokstäver i aliaset tack'
    end
    if self.alias.length > 35
      errors.add :alias, 'Max 35 bokstäver i aliaset'
    end
    if self.alias =~ /[<>]/
      errors.add :alias, ERB::Util.h('Nej! Inga < eller > i aliaset')
    end
    if ((page_alias = Alias.find_by_alias(self.alias)) and not page_alias == self) or
      (page = Page.find_by_title(self.alias) and not page == self.page)
      errors.add :alias, 'Det finns redan ett alias med samma titel'
    end
  end
end

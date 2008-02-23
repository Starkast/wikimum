class Markup

  # Default is Markdown
  def self.to_html(text, markup)
    return '' if text.to_s.empty?

    # Wiki links
    wikified = text.gsub(/\[\[([\d\w\sÅÄÖåäö_:-]{1,35})\]\]/i) do
      "{{#{$1}}}"
    end
        
    #html_escape	=	{ '&' => '&amp;', '"' => '&quot;', '>' => '&gt;', '<' => '&lt;' }
    #wikified.gsub!(/[&"><]/) { |special| html_escape[special] }

    case markup.to_s.downcase
    when 'textile'
      RedCloth.new(wikified).to_html
    when 'markdown'
      BlueCloth.new(wikified).to_html
    else
      text
    end
  end

end

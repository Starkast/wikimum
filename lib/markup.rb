class Markup

  # Default is Markdown
  def self.to_html(text, markup)
    return '' if text.to_s.empty?

    # Wiki links
    wikified = text.gsub(/\[\[([\d\w\sÅÄÖåäö_:-]{1,35})\]\]/i) do
      "{{#{$1}}}"
    end
    # Link URLs
    #wikified.gsub!(/((ftp|http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?)/) do
    #   "<a href=\"#{$1}\">#{$1}</a>"
    #end
        
    #html_escape	=	{ '&' => '&amp;', '"' => '&quot;', '>' => '&gt;', '<' => '&lt;' }
    #wikified.gsub!(/[&"><]/) { |special| html_escape[special] }

    case markup.to_s.downcase
    when 'textile'
      textile = RedCloth.new(wikified)
      textile.to_html
    when 'markdown'
      BlueCloth.new(wikified).to_html
    else
      text
    end
  end

end

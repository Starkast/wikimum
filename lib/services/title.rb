class Title
  def initialize(title)
    @title = title
  end

  def to_s
    @title
  end

  def first_char
    char = @title[0]

    if char =~ /[a-z]/i
      char.upcase
    else
      '#'
    end
  end
end

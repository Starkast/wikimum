# Helpers that will be availible in the whole app

class Time

  def without_hours # minutes and seconds
    self.at_beginning_of_day
  end

  # Credit to Cocoa for the idea
  #
  # Options are used to set a minimum accuracy
  def age_in_swedish_words(options = Hash.new)
    to_time = Time.now unless to_time

    age_in_minutes = ((to_time - self) / 60).round.abs
    age_in_seconds = ((to_time - self)).round.abs

    if options[:minutes]
      case age_in_minutes
      when 0..1
        case age_in_seconds
        when 0..59 then  "cirka 1 minut"
        else             "1 minut"
        end
      when 2..45      then "#{age_in_minutes} minuter"
      when 46..90     then "cirka 1 timme"
      when 80..1440   then "cirka #{(age_in_minutes.to_f / 60.0).round} timmar"
      when 1441..2880 then "1 dag"
      else                 "#{(age_in_minutes / 1440).round} dagar"
      end
    elsif options[:hours]
      case age_in_minutes
      when 0..90      then "cirka 1 timme"
      when 80..1440   then "cirka #{(age_in_minutes.to_f / 60.0).round} timmar"
      when 1441..2880 then "1 dag"
      else                 "#{(age_in_minutes / 1440).round} dagar"
      end
    elsif options[:days]
      case age_in_minutes
      when 0..1440    then "mindre än 1 dag" 
      when 1441..2880 then "1 dag"
      else                 "#{(age_in_minutes / 1440).round} dagar"
      end
    else
      case age_in_minutes
      when 0..1
        case age_in_seconds
        when 0..5   then "mindre än 5 sekunder"
        when 6..10  then "mindre än 10 sekunder"
        when 11..20 then "mindre än 20 sekunder"
        when 21..40 then "en halv minut"
        when 41..59 then "mindre än en minut"
        else             "1 minut"
        end
      when 2..45      then "#{age_in_minutes} minuter"
      when 46..90     then "cirka 1 timme"
      when 80..1440   then "cirka #{(age_in_minutes.to_f / 60.0).round} timmar"
      when 1441..2880 then "1 dag"
      else                 "#{(age_in_minutes / 1440).round} dagar"
      end
    end
  end

end

class String
  
  # Removes all weird characters
  def to_shorthand
    self.space_to_underline.gsub(/[^\d\w\sÅÄÖåäö_:-]/i, '')
  end
  
  def to_shorthand!
    self.space_to_underline.gsub!(/[^\d\w\sÅÄÖåäö_:-]/i, '')
  end
  
  def space_to_underline
    self.gsub(' ', '_')
  end

  def space_to_underline!
    self.gsub!(' ', '_')
  end

  def underline_to_space
    self.gsub('_', ' ')
  end

  def underline_to_space!
    self.gsub!('_', ' ')
  end

  def first_char
    if str = /[a-z]/i.match(self[0..1])
      str[0]
    else
      '#'
    end
  end

  def first_word
    unless self.empty?
      self.match(/^[\-a-zåäöÅÄÖ]+/i).to_s
    end
  end

end

class Fixnum

  def none_one_or_number_in_swedish
    case self
    when 0 then 'inga'
    when 1 then 'en'
    else        self.to_s
    end
  end

  def none_or_number_in_swedish
    if self == 0
      'inga'
    else
      self.to_s
    end
  end

end

#module ActionView
#  module Helpers
#    module ActiveRecordHelper
#      def error_messages_for(object_name)
#        object = instance_variable_get("@#{object_name}")
#
#        unless object.errors.empty?
#          error = "<h3 class=\"error\">Vad gick fel?</h3>"
#          error << "\n<ul class=\"error\">"
#          object.errors.each do |attr_name, message|
#            error << "\n  <li class=\"error\">#{message}</li>"
#          end
#          error << "\n</ul>"
#        end
#      end
#    end
#  end
#end
#
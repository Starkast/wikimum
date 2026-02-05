# frozen_string_literal: true

require "logger"

class LogfmtLogger
  def initialize(output = $stdout)
    @logger = Logger.new(output)
    @logger.formatter = method(:format_logfmt)
  end

  def info(**kwargs)
    @logger.info(kwargs)
  end

  def warn(**kwargs)
    @logger.warn(kwargs)
  end

  def error(**kwargs)
    @logger.error(kwargs)
  end

  private

  def format_logfmt(severity, _time, _progname, kwargs)
    level = severity.downcase
    pairs = [["at", level]]
    kwargs.each { |k, v| pairs << [k, v] }
    pairs.map { |k, v| "#{k}=#{format_value(v)}" }.join(" ") + "\n"
  end

  def format_value(value)
    str = value.to_s
    if str.empty? || str.match?(/[\s="]/)
      "\"#{str.gsub('\\', '\\\\\\\\').gsub('"', '\\"')}\""
    else
      str
    end
  end
end

class RssController < ApplicationController

  def latest
    @pages = Page.find_all_by_date
    render :layout => false
  end

  def list
    @pages = Page.find_all_by_section
    render :layout => false
  end

  protected

  def set_charset
    headers["Content-Type"] = "text/xml; charset=utf-8" 
  end

end

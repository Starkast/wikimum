# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'user_system'

class ApplicationController < ActionController::Base

  include UserSystem
  helper :user
  #model :user

  layout 'main'

  before_filter :set_charset, :load_current_user, :check_flashes
  after_filter  :fix_unicode_for_safari, :store_location

  def page_not_found
    if params[:controller] == 'page' and @current_user.has_create_permission?
      flash[:notice] = 'Sidan finns inte, du får skapa den'
      redirect_to page_new_url(:id => params[:id])
    else
      headers["Code"] = 404
      flash[:error] = 'Sidan hittades inte.'
      redirect_to page_list_url(:id => nil)
    end
  end

  def permission_denied
    access_denied
  end

  def logged_in?
    @current_user.real?
  end
  helper_method :logged_in?

  def registration_available?
    WikiConf['user']['registration']
  end
  helper_method :registration_available?

  def default_url_options(options)
    { :protocol => WikiConf['main']['default_protocol'] }
  end

  def load_current_user
    if session[:user_login] or cookies[:cookie_token]
      user = User.find_by_login(session[:user_login]) || User.find_by_cookie_token(cookies[:cookie_token])
      if user and not session[:user_login] # Then it was a cookie login
        session[:user_login] = user.login
        user.update_attribute(:last_login, Time.now)
        user.update_attribute(:ip, request.remote_ip.split(',').first)
      end
      
      if user.nil? # Kick out the user and make him a guest
        session[:user_login] = nil
        cookies.delete :cookie_token
        user = Guest.new(:ip => request.remote_ip.split(',').first)
        flash[:error] = 'Du finns inte med i systemet, adjö!'
        flash[:logout] = true
        redirect_back_or_default index_url
      end
    else
      user = Guest.new(:ip => request.remote_ip.split(',').first)
    end
    
    @current_user = user
  end

  def xhr_call
    request.xhr?
  end

  protected
  
  # Not sure if this is such a good idea
  # UTF-8 is problematic
  def set_charset
    if not request.xhr?
      headers["Content-Type"] = "text/html; charset=utf-8"
    end
  end

  def fix_unicode_for_safari
    if headers["Content-Type"] == "text/html; charset=utf-8" and
      request.env['HTTP_USER_AGENT'].to_s.include? 'AppleWebKit' and 
      request.xhr?

      response.body = response.body.gsub(/([^\x00-\xa0])/u) do |s|
        "&#x%x;" % $1.unpack('U')[0]
      end
    end
  end

  # Do not store XMLHttpRequests or POSTs.
  def store_location
    if response.headers['Status'] == '200 OK' and not 
      (request.post? or request.xhr?) then
      session[:return_to] = request.request_uri unless request.request_uri.include? 'rss'
    end
  end

  # Check if the referer is the same as the request, then it's probably
  # a redirect loop. Not 100% accurate
  def redirect_loop?
    unless request.referer.nil?
      request.referer.include? request.request_uri
    end
  end

  # Remove errors if the user is on its way out
  def check_flashes
    flash.delete(:error) if flash[:logout]
  end

end

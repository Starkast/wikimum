module UserSystem

  protected

  def authorize?(user)
    true
  end

  def protect?(action)
    true
  end

  def login_required
    if not protect?(action_name)
      return true
    end

    if session[:user_login] and authorize?(@current_user)
      return true
    end

    access_denied
    return false
  end

  def admin_required
    if not protect?(action_name)
      return true
    end

    if session[:user_login] and @current_user.admin?
      return true
    end

    access_denied
    return false
  end

  def login_forbidden
    if @current_user.guest?
      return true
    end

    access_denied
    return false
  end

  def access_denied(message = 'Förbjudet!')
    if request.xhr?
      render :text => "<span class=\"error\">#{message}</span>"
    else
      headers["Code"] = 403
      flash[:error] = message
      redirect_back_or_default index_url
    end
  end

  def redirect_back_or_default(default)
    if session[:return_to].nil? or dont_redirect_back 
      redirect_to default
    else
      redirect_to session[:return_to]
      session[:return_to] = nil
    end
  end

  private

  def dont_redirect_back
    flash[:logout] || flash[:revoked_permission]
  end

end

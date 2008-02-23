class UserController < ApplicationController

  before_filter :xhr_call, :only => :show_password_area
  before_filter :login_forbidden,
    :only => [ 
      :login, 
      :signup, 
      :recover_password 
    ]
  before_filter :login_required, 
    :except => [ 
      :login, 
      :signup, 
      :recover_password 
    ]
  before_filter :admin_required, 
    :except => [ 
      :signup,
      :show, 
      :edit_self, 
      :login, 
      :recover_password,
      :show_password_area, 
      :logout 
    ]
 
  def show
    @user = User.find_by_login(params[:id])
    user_not_found if @user.nil?
  end

  def list
    @users = User.find(:all, :conditions => "users.type = ''", :include => [ :permissions, :groups ])
  end

  def login
    case request.method
    when :post
      if params[:auth] and (params[:auth][:login].empty? or params[:auth][:password].empty?)
        flash[:notice] = 'Du bör fylla i mer användarinformation i login-fälten'
        redirect_back_or_default index_url
        return
      end
      @user          = User.new(params[:auth])
      logged_in_user = @user.attempt_login(request.remote_ip) # This will be the @current_user here
      if logged_in_user
        @current_user = logged_in_user
        session[:user_login] = @current_user.login
        
        if params[:auth][:use_cookie] == "1"
          cookies[:cookie_token] = { :value => @current_user.cookie_token, :expires => 1.year.from_now }
        end
        
        if @current_user.last_login
          flash[:confirm] = "Välkommen tillbaka #{@current_user.name.first_word}!"
        else
          flash[:confirm] = "Hej och och välkommen #{@current_user.name.first_word}."
        end
      else
        flash[:error] = 'Gick inte att verifiera användaren'
      end
    end

    redirect_back_or_default index_url
  end

  def logout
    cookies.delete :cookie_token
    session[:user_login] = nil
    flash[:confirm] = 'Du har loggats ut från systemet, välkommen åter!'
    flash[:logout]  = true
    redirect_back_or_default index_url
  end

  def signup
    if not registration_available?
      permission_denied; return
    end

    case request.method
    when :get
      @user = User.new
    when :post
      @user = User.new(params[:user])
      @user.new_password = true

      if @user.save
        redirect_to index_url
        flash[:confirm] = 'Ett konto har skapats åt dig, du kan nu logga in med ditt användarnamn och lösenord.'
        if WikiConf['mail']['registration_notify']
          begin
            UserNotify.deliver_signup(@user)
          rescue Exception => e
            flash[:error] = 'Gick ej att leverera epost-notifikation'
            logger.error 'Could not send signup notice'
            logger.error e
          end
        end
      else
        flash[:error] = 'Gick inte att skapa användaren'
      end
    end
  end

  def new
    case request.method
    when :get
      @user = User.new
    when :post
      @user              = User.new(params[:user])
      @user.admin        = params[:user][:admin] # Has to be done manually
      @user.new_password = true
      @user.created_by   = @current_user.id

      if @user.save
        redirect_to user_show_url(:id =>@user.login)
        flash[:confirm] = "Användaren <strong>#{@user.login}</strong> har skapats"
      else
        flash[:error] = 'Gick inte att skapa användaren'
      end
    end
  end

  def delete
    @user       = User.find_by_login(params[:id])
    @user_login = @user.login

    if @user.nil?
      if request.xhr?
        @failure = 'Användaren finns inte'
      else
        flash[:error] = 'Användaren finns inte'
        redirect_back_or_default user_list_url; return
      end
    end

    if not @failure
      begin
        if @user.fake_destroy(@current_user)
          @message = "<strong>#{@user_login}</strong> raderades"
        else
          @failure = "<strong>#{@user_login}</strong> gick inte att radera"
        end
      rescue
        @failure = "Du kan inte radera dig själv!"
      end
    end

    if request.xhr?
      @users = User.find_all
      render :partial => 'user_list'
    else
      flash[:error]  = @failure if @failure
      flash[:notice] = @message if @message
      redirect_to :action => :list
      return false
    end
  end

  def edit
    @user = User.find_by_login(params[:id])

    case request.method
    when :get
      if @user == @current_user
        flash[:notice] = 'Du ändrar just nu ditt eget konto'
      end
    when :post
      @user.attributes   = params[:user]
      @user.admin        = params[:user][:admin] # Has to be done manually
      @user.new_password = true if params[:user][:new_password]

      if @user.save
        flash[:confirm] = 'Ändringarna är sparade'
        redirect_to :action => :show, :id => @user.login
      else
        flash[:error] = 'Gick inte att spara ändringen'
      end
    end
  end

  def edit_self
    @user = User.find_by_login(@current_user.login)

    case request.method
    when :post
      @user.attributes   = params[:user]
      @user.new_password = true if params[:user][:new_password]

      if @user.save
        flash[:confirm] = 'Dina ändringar sparades'
        redirect_to user_show_url(:id => @user)
      else
        flash[:error] = 'Gick inte att spara dina ändringar'
      end
    end
  end

  def rescue_password
    
  end

  private

  def user_not_found
    flash[:error] = 'Användaren finns inte'
    if @current_user.admin?
      redirect_back_or_default user_list_url
    else
      redirect_back_or_default page_list_url
    end
  end

end

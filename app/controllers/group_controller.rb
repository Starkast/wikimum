class GroupController < ApplicationController

  before_filter :login_required
  before_filter :admin_required, :except => [ :show ]
  before_filter :xhr_call,
    :only => [
      :create,
      :auto_complete_for_user_login,
      :add_user,
      :remove_user
    ]

  def show
    @group = Group.find_by_name(params[:id])

    if @group.nil?
      flash[:error] = 'Gruppen hittades inte'
      redirect_back_or_default group_list_url
      return
    end
    
    access_denied if not @current_user.admin? or not @current_user.member_of?(@group)
  end

  def list
    @groups = Group.find(:all)
    @group  = Group.new # for the error-messages
  end

  def create
    @group         = Group.new(params[:group])
    @group.creator = @current_user

    if @group.save
      @message = "<strong>#{@group.name}</strong> skapades"
    else
      @failure = 'Gruppen gick ej att skapa'
    end

    # Highlight the new group
    @highlight = @group
    @groups    = Group.find(:all)

    render :partial => 'group_list'
  end

  def delete
    if request.xhr?
      @group = Group.find_by_name(params[:name])
    else
      @group = Group.find_by_name(params[:id])
    end

    if @group.nil? # If no group is found
      @group = Group.new
      @failure = "<strong>#{params[:name]}</strong> hittas inte, kan inte radera"
    else # if it is found
      if @group.destroy
        @message = "<strong>#{@group.name}</strong> raderades"
      else
        @failure = "<strong>#{@group.name}</strong> gick inte att radera"
      end
    end

    @groups = Group.find(:all)

    if request.xhr?
      render :partial => 'group_list'
    else
      flash[:confirm] = @message if @message
      flash[:error]   = @failure if @failure

      redirect_to :action => 'list'
    end
  end

  def auto_complete_for_user_login
    @users = User.search_by_login(params[:user][:login])
    render :partial => 'user/auto_complete_users'
  end

  def add_user
    @user  = User.find_by_login(params[:user][:login])
    @group = Group.find_by_name(params[:group][:name])

    if @user and @group
      if @group.has_member? @user
        @failure = "<strong>#{@user.login}</strong> är redan medlem i gruppen"
      else
        if @user and @group and @group.users << @user
          @message = "<strong>#{@user.login}</strong> har lagts till"
        else
          @failure = "Gick inte att lägga till <strong>#{@user.login}</strong>"
        end
      end
    else # If no user or group is specified
      @failure = 'Objektet gick inte att hitta'
    end

    # Re-fetch so that the users are ordered
    @group = Group.find_by_name(@group.name)
    render :partial => 'users_in_group'
  end

  def remove_user
    @user  = User.find_by_login(params[:user])
    @group = Group.find_by_name(params[:group])

    if @user and @group
      if @group.users.delete @user
        @message = "<strong>#{@user.login}</strong> har tagits bort"
      else
        @failure = "Gick inte att ta bort <strong>#{@user.login}</strong>"
      end
    else
      @failure = 'Objektet gick inte att hitta'
    end

    # Re-fetch so that the users are ordered
    @group = Group.find_by_name(@group.name)

    render :partial => 'users_in_group'
  end

end

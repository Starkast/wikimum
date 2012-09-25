class PageController < ApplicationController

  before_filter :xhr_call, 
    :only => [ 
      :add_permission,
      :remove_permission,
      :edit_permission,
      :update_permission,
      :show_permissions,
      :auto_complete_for_user_login, 
      :auto_complete_for_group_name,
      :check_for_changes,
      :add_alias,
      :remove_alias
    ]

  before_filter :login_required, 
    :except => [ 
      :show, 
      :edit, 
      :list, 
      :latest, 
      :search, 
      :print, 
      :check_for_changes, 
      :cookies 
    ]

  def show
    params[:id] = WikiConf['page']['index'] if params[:index]
    @page = Page.find_by_title(params[:id], @current_user)
    page_not_found if @page.nil?
  end

  def print
    show
    render(:layout => 'print') unless @page.nil?
  end

  def search
    # No keyword
    if params[:q].nil? or params[:q].strip.empty?
      @pages = []
      flash[:notice] = 'Var vänlig fyll i ett sökord'
      unless redirect_loop?
        redirect_back_or_default :action => :search
      end
      return
    end

    @pages = Page.search(params[:q], @current_user)

    case @pages.length
    when 0
      flash[:notice] = "Din sökning gav inga träffar"
      unless redirect_loop?
        redirect_back_or_default :action => :search 
      end
    when 1
      flash[:confirm] = 'Din sökning gav bara denna sida som träff'
      redirect_to page_show_url(:id => @pages.first)
    else 
      flash[:confirm] = "Din sökning gav #{@pages.length} träffar"
    end
  end

  def list
    @pages     = Page.find_all_by_section(params[:id], @current_user)
    @all_pages = Page.find_all_with_read_permission_for(@current_user)
    @sections  = []
    @all_pages.each do |page|
      unless @sections.include? page.section
        @sections << page.section
      end
    end
  end

  def latest
    @pages = Page.find_all_by_date(params[:year], params[:month], params[:day], @current_user)
  end

  def new
    unless @current_user.has_create_permission?
      permission_denied; return
    end

    # Check if page already exist
    if @page = Page.find_by_title(params[:id], @current_user)
      flash[:notice] = 'En sida med detta namn finns redan'
      redirect_to page_show_url(:id => @page)
      return
    end

    case request.method
    when :get
      @page = Page.new
      if not params[:id].nil?
        title = params[:id].to_s.underline_to_space
        @page.title = title.gsub(title.first_char, title.first_char.capitalize)
      end
    when :post
      @page         = Page.new(params[:page])
      @page.updater = @current_user
      @page.creator = @current_user

      if @page.save
        flash[:confirm] = render_to_string :partial => 'messages/page_created'
        redirect_to page_show_url(:id => @page)
      else
        flash[:error] = 'Gick inte att spara'
      end
    end
  end

  def edit
    @page = Page.find_by_title(params[:id], @current_user)
    
    if @page.nil?
      page_not_found; return
    end

    if not @page.write_by?(@current_user)
      permission_denied; return
    end

    case request.method
    when :get
      # Don't use the previous comment
      @page.comment = nil
    when :post
      @page.attributes = params[:page] # Everything but current_user data

      if @page.changed?
        begin
          previous_page = Page.find_by_title(params[:id], @current_user)
          previous_page.revise
        rescue
          flash[:error] = 'Gick inte att spara ny revision'
          return
        end

        begin
          @page.updater = @current_user
          if @page.save
            flash[:confirm] = "<strong>#{@page.title}</strong> sparades"
            redirect_to page_show_url(:id => @page)
          else
            @page.revoke_latest_revision
            flash[:error] = 'Gick inte att spara'
          end
        rescue ActiveRecord::StaleObjectError
          @page.revoke_latest_revision
          flash[:error] = 'Någon ändrade i sidans innehåll medan du jobbade med den, du får komma ihåg dina ändringar och börja om från början'
        end
      else
        flash[:notice] = 'Du har inte modifierat innehållet, sidan sparas inte'
        redirect_to page_show_url(:id => @page)
      end
    end
  end

  def check_for_changes
    page = Page.find_by_title(params[:id], @current_user)

    case
    when page.nil?
      render :text => 'Denna sida finns inte längre!'
    when page.lock_version > params[:lock_version].to_i
      render :text => 'Någon ändrade i sidans innehåll medan du jobbade med den, du får komma ihåg dina ändringar och börja om från början'
    else
      render :text => ''
    end
  end

  def delete
    @page = Page.find_by_title(params[:id], @current_user)

    if @page.nil?
      page_not_found; return
    end

    if not @page.own_by?(@current_user)
      permission_denied; return
    end

    if @page.destroy
      flash[:confirm] = "<strong>#{@page.title}</strong> raderades"
      redirect_to index_url
    else
      flash[:error] = "<strong>#{@page.title}</strong> gick inte att radera"
    end
  end
  
  def add_alias
    if @page = Page.find(params[:page][:id], :include => [:aliases])
      if @page.aliases << Alias.new(params[:alias])
        render :partial => 'aliases'
      else
        @page.reload
        @error = 'Oh'
        render :partial => 'aliases'
      end
    else
      render :text => 'On noes'
    end
  end
  
  def remove_alias
    if @alias = Alias.find(params[:id], :include => [:page]) and @alias.destroy
      @page = @alias.page
      render :partial => 'aliases'
    else
      render :text => 'Oh noes'
    end
  end

  def permission
    @page = Page.find_by_title(params[:id], @current_user)

    if @page.nil?
      page_not_found; return
    end

    if not @page.own_by?(@current_user)
      page_not_found; return
    end

    @global_permission = Permission.find_global_by_page(@page)
    @user_permissions  = Permission.find_with_user_by_page(@page)
    @group_permissions = Permission.find_with_group_by_page(@page)
  end

  # TODO - The eval() is probably not that good
  # Pretty ugly method any way
  def add_permission
    @page = Page.find(params[:page_id])
    type  = eval(params[:permission][:privilege])

    case params[:type]
    when 'global'
      permission = type.new(:global => true)
    when 'user'
      unless user = User.find_by_login(params[:user][:login])
        @failure = "Gick inte att hitta använadren <strong>#{params[:user][:login]}</strong>"
      end
      permission = type.new(:user => user)
    when 'group'
      unless group = Group.find_by_name(params[:group][:name])
        @failure = "Gick inte att hitta gruppen <strong>#{params[:group][:name]}</strong>"
      end
      permission = type.new(:group => group)
    else
      @failure = 'Rättigheten gick inte att initiera'
    end

    if @failure.nil? and @page.permissions << permission
      @message = 'Rättighet skapad'
    else
      @failure = 'Gick inte att skapa rättigheten'
    end
    show_permissions
  end

  def auto_complete_for_user_login
    @users = User.search_by_login(params[:user][:login])
    render :partial => 'user/auto_complete_users'
  end

  def auto_complete_for_group_name
    @groups = Group.search_by_name(params[:group][:name])
    render :partial => 'group/auto_complete_groups'
  end

  def remove_permission
    permission = Permission.find(params[:id])
    if permission.destroy
      @message = 'Rättighet indragen'
    else
      @failure = 'Gick inte att dra in rättigheten'
    end
    show_permissions
  end

  def edit_permission
    @editing = params[:id].to_i
    show_permissions
  end

  def update_permission
    permission_id     = params[:id] || params[:permission][:id]
    permission        = Permission.find(permission_id)
    permission[:type] = params[:permission][:privilege]
    if permission.save
      @message = 'Rättigheten är sparad'
    else
      @failure = 'Gick inte att spara rättigheten'
    end
    show_permissions
  end

  def show_permissions
    @page = Page.find(params[:page_id])
    case params[:type]
    when 'global'
      @global_permission = Permission.find_global_by_page(@page)
      render :partial => 'global_permissions'
    when 'user'
      @user_permissions = Permission.find_with_user_by_page(@page)
      render :partial => 'user_permissions'
    when 'group'
      @group_permissions = Permission.find_with_group_by_page(@page)
      render :partial => 'group_permissions'
    end
  end

end

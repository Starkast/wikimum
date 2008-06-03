class RevisionController < ApplicationController

  helper :page

  def history
    @page = Page.find_by_title(params[:id], @current_user)

    if @page.nil?
      page_not_found; return
    end

    if not @page.read_by?(@current_user)
      permission_denied; return
    end

    @revisions = [@page]
    @revisions.concat @page.revisions.reverse
  end

  def show
    if params[:revision].nil?
      redirect_to page_show_url(:id => params[:id]); return
    end
    
    @page     = Page.find_by_title(params[:id], @current_user)
    @revision = Revision.find_by_page(@page, params[:revision])

    if @page.nil?
      page_not_found; return
    end

    if not @page.read_by?(@current_user)
      permission_denied; return
    end

    if @revision.nil?
      if @page.revision == params[:revision].to_i
        @revision = @page
      else
        flash[:notice] = "Revision #{params[:revision]} finns inte"
        redirect_back_or_default page_show_url(:id => params[:id])
      end
    end
  end

  def print
    show
    unless @page.nil?
      render(:action => 'print', :layout => 'print')
    else
      page_not_found; return
    end
  end

  def diff
    @page = Page.find_by_title(params[:id], @current_user) || Revision.find_by_title(params[:id]).first.page
    @revision = @page # Used by the status information

    if @page.nil?
      page_not_found; return
    end

    if not @page.read_by?(@current_user)
      permission_denied; return
    end

    case @page.revision
    when params[:new].to_i
      @new = @page
    when params[:old].to_i
      @old = @page
    end

    @new ||= Revision.find_by_page(@page, params[:new])
    @old ||= Revision.find_by_page(@page, params[:old])

    if @new.nil? or @old.nil?
      flash[:notice] = 'Hittade inte revisionerna'
      redirect_to revision_history_url(:id => @page); return
    end

    @content_diff     = HTMLDiff.diff(@old.content, @new.content)
    @description_diff = HTMLDiff.diff(@old.description, @new.description) 
  end

end

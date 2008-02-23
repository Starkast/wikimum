class DocumentationController < ApplicationController

  before_filter :xhr_call

  def show_documentation
    session[:show_documentation] = true
    render :nothing => true
  end

  def hide_documentation
    session[:show_documentation] = false
    render :nothing => true
  end

  def change_page
    session[:documentation_page] = params[:id]
    render :partial => params[:id]
  end

end

module ApplicationHelper

  def page_title
    prefix    = WikiConf['title']['prefix']
    suffix    = WikiConf['title']['suffix']
    delimiter = WikiConf['title']['delimiter']

    if @page_title
      if not prefix.nil?
        "#{prefix} #{delimiter} #{@page_title}"
      elsif not suffix.nil?
        "#{@page_title} #{delimiter} #{suffix}"
      else
        @page_title
      end
    else
      prefix || suffix || 'WikImum'
    end
  end

  def site_name
    WikiConf['main']['name'] || 'WikImum'
  end

  def ssl_available?
    WikiConf['main']['ssl_available']
  end

  def page_index
    WikiConf['page']['index']
  end

  def printable?
    controller = @controller.controller_name
    action     = @controller.action_name

    # When are the pages printable?
    case controller
    when 'page'     then action == 'show'
    when 'revision' then action == 'show'
    end
  end

  def wiki_markup(text)
    return '' if text.to_s.empty?
    text.gsub(/\{\{([\d\w\sÅÄÖåäö_:-]{1,35})\}\}/i) do
      link_to $1, page_show_url(:id => $1.gsub(' ', '_'))
    end
  end

  def text_field_with_auto_complete_for_user_login
    text_field_with_auto_complete :user, :login,
      { :maxlength    => 15,
        :size         => 15,
        :autocomplete => 'off' }
  end

  def text_field_with_auto_complete_for_group_name
    text_field_with_auto_complete :group, :name,
      { :maxlength    => 15,
        :size         => 15,
        :autocomplete => 'off' }
  end

  def ajax_messages(object = nil)
    @object = object
    render :partial => 'shared/ajax_messages'
  end

  def show_flash_messages
    buf = ''
    flash.each do |type, value|
      case type
      when :error   then image = 'stop'
      when :notice  then image = 'information'
      when :confirm then image = 'accept'
      else               image = nil
      end

      if not image.nil?
        buf << image_tag("#{image}.png", :class => 'icon', :alt => '')
        buf << " <span class=\"#{type}\">#{value}</span><br />"
      end
    end

    buf
  end

  def user_show_link(user)
    return if user.nil?
    return user.name if (user.is_a?(DeletedUser) or user.is_a?(Guest))
    link_to_if((logged_in? and user.real?), user, user_show_url(:id => user))
  end

  def user_edit_link(user)
    return if not user.real?
    if user == @current_user
      link_to('Ändra ditt konto', user_edit_self_url)
    elsif @current_user.admin?
      link_to('Ändra', user_edit_url(:id => user))
    end
  end

  def user_delete_link(user)
    return if not user.real?
    if @current_user.admin? and user != @current_user
      c = link_to_function('Radera',
        visual_effect(:toggle_blind, 'confirm_deletion', :duration => 0.4))
      c << render(:partial => 'user/confirm_user_deletion')
    end
  end

  def user_ajax_delete_link(user)
    return if not user.real?
    if @current_user.admin? and user != @current_user
      link_to_function('Radera',
        visual_effect(:toggle_appear, "confirm_#{user.login}", :duration => 0.3))
    end
  end

  def page_read_link(page)
    link_to_unless_current('Läs', page_show_url(:id => page)) if page.read_by?(@current_user)
  end

  def page_edit_link(page)
    link_to_unless_current('Ändra', page_edit_url(:id => page)) if page.write_by?(@current_user)
  end

  def page_permission_link(page)
    link_to('Rättigheter', page_permission_url(:id => page)) if page.own_by?(@current_user)
  end

  def page_delete_link(page)
    if page.own_by?(@current_user)
      c = link_to_function('Radera',
        visual_effect(:toggle_blind, "confirm_deletion", :duration => 0.3))
      c << render(:partial => 'page/confirm_page_deletion')
    end
  end

  def group_ajax_delete_link(group)
    if @current_user.admin?
      c = link_to_function('Radera',
        visual_effect(:toggle_blind, "confirm_deletion", :duration => 0.3))
      c << render(:partial => 'group/confirm_group_deletion')
    end
  end

  def group_show_link(group)
    if @current_user.admin?
      link_to 'Hantera', group_show_url(:id => group)
    end
  end

  def revision_history_link(page)
    link_to_if page.write_by?(@current_user), 
      page.revision, 
      revision_history_url(:id => page), 
      :title => 'Se revisionshistoria'
  end

  def document_page_link(name, id)
    link_to_remote(name,
      :update => 'documentation_content',
      :url => {
        :controller => 'documentation', 
        :action => :change_page, 
        :id => id })
  end

  def render_page_information
    case params[:controller] + '/' + params[:action]
    when 'page/show'
      @upper_left_line_text  = render :partial => 'page/edit'
      @upper_right_line_text = render :partial => 'page/revision'
      @lower_left_line_text  = render :partial => 'page/print_link'
      @lower_right_line_text = render :partial => 'page/latest_change'
    when 'page/edit'
      @upper_left_line_text  = render :partial => 'page/edit'
    when 'page/permission'
      @upper_left_line_text  = render :partial => 'page/edit'
      @upper_right_line_text = render :partial => 'page/revision'
    when 'revision/history'
      @upper_left_line_text  = render :partial => 'page/edit'
      @upper_right_line_text = render :partial => 'page/revision'
    when 'revision/show'
      @upper_left_line_text  = render :partial => 'page/edit'
      @upper_right_line_text = render :partial => 'page/revision'
      @lower_left_line_text  = render :partial => 'page/print_link'
    when 'revision/diff'
      @upper_left_line_text  = render :partial => 'page/edit'
      @upper_right_line_text = render :partial => 'page/revision'
    end
  end

  def render_actions
    case params[:controller]
    when 'page'
      if params[:action] =~ /(show|edit|permission)/
        render :partial => 'page/actions'
      end
    when 'revision'
      if params[:action] =~ /(history|show|diff)/
        render :partial => 'page/actions'
      end
    when 'user'
      if params[:action] =~ /(show|edit)/
        render :partial => 'user/actions'
      end
    when 'group'
      if params[:action] =~ /(show)/
        render :partial => 'group/actions'
      end
    end
  end

  def render_status
    case params[:controller]
    when 'page'
      if params[:action] =~ /(show|edit|permission)/
        render :partial => 'page/status'
      end
    when 'revision'
      if params[:action] =~ /(show|diff)/
        render :partial => 'revision/status'
      end
    when 'group'
      if params[:action] =~ /(show)/
        render :partial => 'group/status'
      end
    end
  end
  
  def markups_available
    %w( Textile Markdown HTML )
  end

end

module UserHelper

  def last_login_in_swedish_words(user)
    if user.last_login.nil?
      'Aldrig'
    else
      user.last_login.age_in_swedish_words(:minutes => true) + ' sen'
    end
  end

  def actions(user)
    [ user_edit_link(user),
      user_delete_link(user) ]
  end

  def name_link(user)
    link_to user, user_show_url(:id => user)
  end
  
  def markup_select
    select :user, :markup, %w( Textile Markdown Ingen )
  end

end

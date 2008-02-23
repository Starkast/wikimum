ActionController::Routing::Routes.draw do |map|

  # Page
  map.index '', 
    :controller => 'page', 
    :action => 'show', 
    :index => true

  map.page_new 'page/new/:id', 
    :controller => 'page', 
    :action => 'new',
    :id => nil

  map.page_search 'search/', 
    :controller => 'page', 
    :action => 'search'

  map.page_edit 'page/edit/:id', 
    :controller => 'page', 
    :action => 'edit'

  #map.page_show 'page/show/:id', 
  #  :controller => 'page', 
  #  :action => 'show'


  map.page_print 'page/print/:id',
    :controller => 'page',
    :action => 'print'

  map.page_permission 'page/permission/:id', 
    :controller => 'page', 
    :action => 'permission'

  # %23 => # in UTF-8
  map.page_list 'page/list/:id', 
    :controller => 'page', 
    :action => 'list',
    :section => nil,
    :requirements => { :section => /(%23|[A-Z])/ }

  map.page_latest 'page/latest/:year/:month/:day', 
    :controller => 'page',
    :action => 'latest', 
    :year => nil, 
    :month => nil, 
    :day => nil,
    :requirements => { 
      :year => /\d{4}/, 
      :day => /\d{1,2}/, 
      :month => /\d{1,2}/ }

  # RSS

  map.rss_list 'rss/list', 
    :controller => 'rss', 
    :action => 'list'

  map.rss_latest 'rss/latest', 
    :controller => 'rss', 
    :action => 'latest'

  # Revision

  map.revision_history 'revision/history/:id', 
    :controller => 'revision',
    :action => 'history'

  map.revision_show 'revision/show/:id/:revision',
    :controller   => 'revision',
    :action       => 'show',
    :requirements => { :revision => /([0-9]+)/ }

  map.revision_print 'revision/print/:id/:revision',
    :controller   => 'revision',
    :action       => 'print',
    :requirements => { :revision => /([0-9]+)/ }

  map.revision_diff 'revision/diff/:id/:new/:old',
    :controller   => 'revision',
    :action       => 'diff',
    :requirements => { :new  => /([0-9]+)/, :old  => /([0-9]+)/ }

  # User

  map.user_edit_self 'user/edit_self', 
    :controller => 'user', 
    :action => 'edit_self'

  map.user_edit 'user/edit/:id', 
    :controller => 'user', 
    :action => 'edit'#,
    #:requirements => { :id => /([0-9A-Z])/i }

  map.user_show_self 'user/show_self', 
    :controller => 'user', 
    :action => 'show_self'

  map.user_show 'user/show/:id', 
    :controller => 'user', 
    :action => 'show'#,
    #:requirements => { :id => /([0-9A-Z])/i }
  
  map.user_list 'user/list', 
    :controller => 'user', 
    :action => 'list'

  map.user_login 'login',
    :controller => 'user',
    :action => 'login'

  map.user_logout 'logout',
    :controller => 'user',
    :action => 'logout'

  map.user_signup 'signup',
    :controller => 'user',
    :action => 'signup'

  # Group
 
  map.group_list 'group/list', 
    :controller => 'group', 
    :action => 'list'

  map.group_show 'group/show/:id', 
    :controller => 'group', 
    :action => 'show'#,
    #:requirements => { :id => /([0-9A-Z])/i }

  map.page_show ':id', 
    :controller => 'page', 
    :action => 'show'

  # Default, lowest priority
  map.connect ':controller/:action/:id'

end

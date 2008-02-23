module PageHelper

  def permission_list(type = nil, selected = nil)
    list = [ 
      [ ReadPermission.new.to_s, ReadPermission.new.class.to_s ],
      [ WritePermission.new.to_s, WritePermission.new.class.to_s ]
    ]

    if not type == 'global'
      list << [OwnPermission.new.to_s, OwnPermission.new.class.to_s]
    end

    select(:permission, :privilege, list)
  end

  def actions(page)
    [ page_edit_link(page),
      page_permission_link(page),
      page_delete_link(page) ]
  end

  def title_link(page)
    link_to page, page_show_url(:id => page)
  end
end

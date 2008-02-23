module GroupHelper

  # Which object should be named 'new'?
  def find_out_new_group_id(group, new_group = nil)
    salt = "_#{(rand * 100).to_i}"

    return (group.name + salt) if new_group.nil?
    if group.name == new_group.name
      'new_group'
    else
      (group.name + salt)
    end
  end

  def actions(group)
    [ group_show_link(group),
      group_ajax_delete_link(group) ]
  end

  def name_link(group)
    link_to group, group_show_url(:id => group)
  end

end

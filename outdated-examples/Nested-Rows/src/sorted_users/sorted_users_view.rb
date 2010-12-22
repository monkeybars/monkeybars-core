class SortedUsersView < ApplicationView
  set_java_class 'sorted_users.SortedUsersFrame'
  
  SORT_BY_TRANSLATION = {:first_name => "First Name", :last_name => "Last Name", :age => "Age"}
  
  map :view => 'sort_by_combo_box.selected_item', :model => :sort_by_field, :translate_using => SORT_BY_TRANSLATION
  
  #nest :sub_view => :users, :view => :users_panel
  # Normally, the nesting that's commented above would do fine.
  # however, with GridLayouts a validate is needed (see SortedUsersView#add_user)
  nest :sub_view => :users, :using => [:add_user, :remove_user]
  
  def add_user(user_view, user_component, model, transfer)
    users_panel.add user_component
    users_panel.validate
  end
  
  def remove_user(user_view, user_component, model, transfer)
    users_panel.remove user_component
  end
end

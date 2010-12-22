class ListView < ApplicationView
  set_java_class 'list.ListFrame'
  
  map :view => 'items_list.model', :transfer => :list, :using => [:to_list_model, nil]
  
  nest :sub_view => :search, :view => :search_landing_panel
  
  def load
    search_landing_panel.remove_all
  end
  
  def to_list_model(list)
    Java::javax.swing::DefaultComboBoxModel.new(list.to_java(:String))
  end
end

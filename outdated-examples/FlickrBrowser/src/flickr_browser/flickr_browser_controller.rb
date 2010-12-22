class FlickrBrowserController < ApplicationController
  set_model 'FlickrBrowserModel'
  set_view 'FlickrBrowserView'
  set_close_action :exit

  def go_button_action_performed
    update_model(view_state.first, :search_terms)
    model.search
    update_view
  end
  
  def photos_tree_tree_will_expand(event)
    expanding_node = event.path.last_path_component
    transfer[:expanding_node] = expanding_node
    transfer[:photo_sizes] = model.find_sizes_by_id(expanding_node.user_object.id)
    signal(:expand_node)
  end
  
  def photos_tree_value_changed(event)
    photo_size = event.path.last_path_component.user_object
    if photo_size.respond_to? :source
      transfer[:image_url] = photo_size.source.gsub(/[\\ ]/, '')
      signal(:update_image)
    end
  end
end
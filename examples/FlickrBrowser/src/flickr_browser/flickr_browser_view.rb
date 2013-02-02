java_import javax.swing.tree.DefaultMutableTreeNode
java_import javax.swing.ImageIcon
java_import java.net.URL

require 'flickraw'

class FlickrBrowserView < ApplicationView
  set_java_class 'FlickrBrowser'

  map :view => "photos_tree.model", :model => :search_results, :using => [:build_tree_nodes, nil]
  map :view => "photos_tree.model.root.user_object", :model => :search_terms, :using => [:default, nil]
  map :view => "search_field.text", :model => :search_terms
 
  def load
    photos_tree.model = javax.swing.tree.DefaultTreeModel.new(nil, true)
  end
  
  def build_tree_nodes(search_results)
    root = DefaultMutableTreeNode.new("updating...", true)
    search_results.each_with_index do |photo, index|
      root.add DefaultMutableTreeNode.new(photo, true)
    end
    javax.swing.tree.DefaultTreeModel.new(root, true)
  end
  
   define_signal :name => :expand_node, :handler => :expand_node
  def expand_node(model, transfer)
    expanding_node = transfer[:expanding_node]
    transfer[:photo_sizes].each do |size|
      expanding_node.add DefaultMutableTreeNode.new(size, false)
    end
    photos_tree.model.node_structure_changed expanding_node
  end
  
   define_signal :name => :update_image, :handler => :update_image
  def update_image(model, transfer)
    image_label.icon = ImageIcon.new(URL.new(transfer[:image_url])) 
  end
end

# Patch the FlickRaw class to return the correct value when being used as a node value
class FlickRaw::Response
  def to_s
    if respond_to? :title
      title
    else
      label
    end
  end

end

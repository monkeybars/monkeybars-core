#require 'resolver'
#$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../src")

require 'manifest'
require 'flickr_browser/flickr_browser_controller'

FlickrBrowserController.set_view "DummyObject" 
FlickrBrowserController.set_model "DummyObject"

class DummyObject
  def method_missing(method, *args, &block); self; end
end

describe FlickrBrowserController, "go_button_action_performed" do
  before(:each) do
    @controller = FlickrBrowserController.instance
  end
  
  class MockModel
    attr_accessor :search_terms
    def initialize; @search_terms = "monkeybars"; end
  end
  
  it "triggers a flickr search on the model" do
    def @controller.view_state; [MockModel.new, nil]; end
    
    @controller.send(:model).should_receive(:search_terms=).with("monkeybars")
    @controller.send(:model).should_receive :search
    @controller.should_receive :update_view
    
    @controller.go_button_action_performed
  end
end

describe FlickrBrowserController, "photos_tree_tree_will_expand" do
  before(:each) do
    @controller = FlickrBrowserController.instance
  end
  
  mock_event = DummyObject.new
  
  it "sets image size data in the transfer and triggers the view's node expansion" do
    @controller.send(:model).should_receive(:find_sizes_by_id).and_return(:sizes)
    @controller.should_receive(:signal).with(:expand_node)
    
    @controller.photos_tree_tree_will_expand(mock_event)
    @controller.send(:transfer)[:expanding_node].should == mock_event
    @controller.send(:transfer)[:photo_sizes].should == :sizes
  end
end

describe FlickrBrowserController, "photos_tree_value_changed" do
  before(:each) do
    @controller = FlickrBrowserController.instance
  end
  
  mock_event = DummyObject.new
  
  it "sets the image source in the transfer and triggers the view's update" do
    def mock_event.source; "http://www.testdomain.com/image"; end
    @controller.send(:transfer)[:image_url] == "http://www.testdomain.com/image"
    @controller.should_receive(:signal).with(:update_image)
    @controller.photos_tree_value_changed(mock_event)
  end
end
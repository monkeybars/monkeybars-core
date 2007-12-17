$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'java'
require 'monkeybars/view'
require 'monkeybars/controller'
require 'spec/unit/test_files.jar'
include_class 'java.awt.event.ActionEvent'
include_class 'java.awt.event.MouseEvent'


class TestView < Monkeybars::View
  set_java_class 'org.monkeybars.TestView'
end

describe "controller instantiation" do
  before(:each) do
    Object.send(:remove_const, :TestController) if Object.const_defined? :TestController
  end
  
  it "should only create one instance by default" do
    class TestController < Monkeybars::Controller; end
    
    t = TestController.instance
    t2 = TestController.instance
    t.should equal(t2)
  end
  
  it "should cache the normalized names of objects that have listeners assigned to them" do
    class TestController < Monkeybars::Controller
      set_view "TestView"
      add_listener :type => :action, :components => ["testButton"]
      add_listener :type => :document, :components => ["testTextField.document"]
      add_listener :type => :mouse
    end
    
    t = TestController.instance
    t.instance_variable_get("@__event_callback_mappings").values.should include("test_button")
    t.instance_variable_get("@__event_callback_mappings").values.should include("test_text_field_document")
    t.instance_variable_get("@__event_callback_mappings").values.should include("test_label") # from global key mapping
    t.close
  end
  
  it "should allow the creation of multiple instances when 'allow :multiple' is declared"
end

describe "handle_event method" do
  before(:each) do
    Object.send(:remove_const, :TestController) if Object.const_defined? :TestController
    
    class TestController < Monkeybars::Controller
      set_view "TestView"
      add_listener :type => :action, :components => ["testButton"]
      add_listener :type => :document, :components => ["testTextField.document"]
      add_listener :type => :key
      
      def test_button_action_performed(event)
        $test_button_action_performed = true
      end
      
      def mouse_clicked(event)
        $mouse_clicked = true
      end
      
    end
  end
  
  it "should try to call the most specific handler available first" do
    $test_button_action_performed = false
    t = TestController.instance
    target_component = t.instance_variable_get("@__view").get_field_value("testButton")
    event = ActionEvent.new(target_component, ActionEvent::ACTION_PERFORMED, "")
    t.handle_event('action_performed', event)
    $test_button_action_performed.should == true
    
    t.close
  end
  
  it "should call a global event handler if no specific component handler is defined" do
    $mouse_clicked = false
    t = TestController.instance
    target_component = t.instance_variable_get("@__view").get_field_value("testLabel")
    event = MouseEvent.new(target_component, MouseEvent::MOUSE_PRESSED, 0, 0, 0, 0, 1, false)
    t.handle_event("mouse_clicked", event)
    $mouse_clicked.should == true
    t.close
  end
  
end

describe "Controller's add_handler_for method" do
  before(:each) do
    Object.send(:remove_const, :TestController) if Object.const_defined? :TestController
  end
  
  it "does not overwrite the controller's method_missing method" do
    class TestController < Monkeybars::Controller
      set_view "TestView"
      
      add_listener :type => :action, :components => ["testButton"]
      
      def method_missing(method, *args, &block)
	return "original method missing"
      end
    end
    
    t = TestController.instance
    t.foobar.should == "original method missing"
    t.close
  end
end

describe "Controller's view_state method" do
  before(:each) do
    Object.send(:remove_const, :TestController) if Object.const_defined? :TestController
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    Object.send(:remove_const, :TestModel) if Object.const_defined? :TestModel
  end
  
  it "returns the view's state as a model" do  
    class TestModel
      attr_accessor :text
      def initialize; @text= ""; end
    end
    
    class TestView < Monkeybars::View
      set_java_class "org.monkeybars.TestView"
      map :view => "testTextField.text", :model => :text
    end
    
    class TestController < Monkeybars::Controller
      set_view "TestView"
      set_model "TestModel"
    end
    
    t = TestController.instance
    
    t.send(:view_state).text.should == "A text field"
    t.instance_variable_get("@__view").testTextField.text = "test data"
    t.send(:view_state).text.should == "test data"
    t.close
  end
end

describe "Controller's update_model method" do
  before(:each) do
    Object.send(:remove_const, :TestController) if Object.const_defined? :TestController
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    Object.send(:remove_const, :TestModel) if Object.const_defined? :TestModel
  end
  
  it "updates the declared properties of the model from the view_state" do
    class TestModel; attr_accessor :text, :text2, :text3; end
    class TestController < Monkeybars::Controller; set_model "TestModel"; end
    
    t = TestController.instance
    m = TestModel.new
    m.text = "some test data"
    m.text2 = "some test data"
    m.text3 = "some test data"
    
    t.send(:model).text = ""
    t.send(:model).text2 = ""
    t.send(:model).text2 = ""
    t.send(:update_model, m, :text, :text3)
    t.send(:model).text.should == "some test data"
    t.send(:model).text2.should == ""
    t.send(:model).text3.should == "some test data"
    t.close
  end
  
end
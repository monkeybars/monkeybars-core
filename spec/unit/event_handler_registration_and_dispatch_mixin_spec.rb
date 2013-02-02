require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'monkeybars/view'
require 'monkeybars/controller'
require 'monkeybars/event_handler_registration_and_dispatch_mixin'
require 'spec/unit/test_files.jar'

class RealFormTestView < Monkeybars::View
  set_java_class 'org.monkeybars.TestView'
end

describe Monkeybars::Controller, "#handle_event" do
  before(:each) do
    class HandleEventController < Monkeybars::Controller
      set_view "RealFormTestView"
      add_listener :type => :action, :components => ["testButton"]
      add_listener :type => :document, :components => ["testTextField.document"]
      
      def test_button_action_performed
        $test_button_action_performed = true
      end
      
      def action_performed
	$action_performed = true
      end
    end
  end
  
  it "should try to call the most specific handler available first" do
    $test_button_action_performed = false
    $action_performed = false
    t = HandleEventController.instance
    target_component = t.instance_variable_get("@__view").get_field_value("testButton")
    event = ActionEvent.new(target_component, ActionEvent::ACTION_PERFORMED, "")
    t.handle_event("test_button", 'action_performed', event)
    $test_button_action_performed.should be_true
    $action_performed.should be_false
    
    t.close
  end

  it "clears the memoized view state after all handlers have been run" do
    class MemoizationTestModel
      attr_accessor :foo, :bar
      def initialize
	@foo = 47
        @bar = "Test data"
      end
    end
    class ClearMemoizedController < Monkeybars::Controller
      set_model "MemoizationTestModel"
      set_view "RealFormTestView"
      
      def test_button_action_performed; end
    end
    
    controller = ClearMemoizedController.instance
    view_state = controller.send(:view_state)
    controller.send(:instance_variable_get, "@__view_state").should_not be_nil
    view_state.model.foo.should == 47
    view_state.model.bar.should == "Test data"
    controller.send(:handle_event, :test_button, :action_performed, "fake event")
    controller.send(:instance_variable_get, "@__view_state").should be_nil
  end
end

describe Monkeybars::View, "#handle_event" do
  class HandleEventView < Monkeybars::View
    set_java_class 'org.monkeybars.TestView'
    
    def test_button_action_performed
      $test_button_action_performed = true
    end

    def action_performed
      $action_performed = true
    end
  end
  
  it "should try to call the most specific handler available first" do
    $test_button_action_performed = false
    $action_performed = false
    v = HandleEventView.new
    event = ActionEvent.new(v.testButton, ActionEvent::ACTION_PERFORMED, "")
    v.handle_event("test_button", 'action_performed', event)
    $test_button_action_performed.should be_true
    $action_performed.should be_false
  end
end

describe Monkeybars::Controller, "#add_handler_for" do
  
  it "does not overwrite the controller's method_missing method" do
    class AddHandlerForController < Monkeybars::Controller
      set_view "RealFormTestView"
      
      add_listener :type => :action, :components => ["testButton"]
      
      def method_missing(method, *args, &block)
	return "original method missing"
      end
    end
    
    t = AddHandlerForController.instance
    t.foobar.should == "original method missing"
    t.close
  end
end

describe Monkeybars::Controller, "implicit handler registration" do
  
  it "detects event names in methods and adds an appropriate listener during instantiation" do
    class ImplicitRegisterView < Monkeybars::View
      set_java_class "org.monkeybars.TestView"
      
      def add_handler(handler, component)
        handler.type.should == "Action"
        handler.instance_variable_get("@component_name").should == "test_button"
        component.should == "test_button"
        $add_handler_called = true
      end
    end
    
    class ImplicitRegisterController < Monkeybars::Controller
      set_view "ImplicitRegisterView"
      
      def test_button_action_performed; end
    end
    
    t = ImplicitRegisterController.instance
    $add_handler_called.should be_true
    t.close
  end

  it "detects a ! at the end of implicit handlers and sets the handler to automatically call update_view" do
    view_class = Class.new(Monkeybars::View) do
      set_java_class "org.monkeybars.TestView"
      attr_accessor :view_was_updated

      raw_mapping :test_mapping, :test_mapping

      def test_mapping(model, transfer)
        @view_was_updated = true
      end
    end
    view = view_class.new

    controller = Class.new(Monkeybars::Controller) do
      set_view { view }
      set_model { Object.new }

      def test_button_action_performed!; end
    end

    c = controller.instance
    c.instance_variable_get("@__view").get_field_value("testButton").do_click
    view.view_was_updated.should be_true
  end
  

  ##it "does not try to implicitly add methods that exist on the base Controller class"
  ##it "does not add an implicit handler if an explict handler of that type was already added for that component"
  ##it "detects the type of the listener to use for the component when using an implicit handler"
  ##it "detects when a new method is added and registers a new listener if appropriate"
end

describe Monkeybars::Controller, "define_handler (class-level)" do
  class MultiHandlerController < Monkeybars::Controller
    set_view 'RealFormTestView'
  end

  it "should support multiple handlers for the same event when no explicit method is declared in the controller" do
    callback_count = 0
    
    MultiHandlerController::define_handler(:test_button_action_performed) do
      callback_count += 1
    end
    
    MultiHandlerController::define_handler(:test_button_action_performed) do
      callback_count += 1
    end
    
    controller = MultiHandlerController.instance
    controller.instance_variable_get("@__view").get_field_value("testButton").do_click
    callback_count.should == 2
  end
  
  it "should support multiple handlers for the same event even when there is an explicit callback method declared in the controller" do
    class MultiHandlerController < Monkeybars::Controller
      attr_accessor :callback_count
      def test_button_action_performed
        @callback_count += 1
      end
    end

    callback_count = 0    
    MultiHandlerController::define_handler(:test_button_action_performed) do
      callback_count += 1
    end
    
    controller = MultiHandlerController.instance
    controller.callback_count = 0
    controller.instance_variable_get("@__view").get_field_value("testButton").do_click
    (callback_count + controller.callback_count).should == 2
  end
end

describe Monkeybars::Controller, "#define_handler (instance-level)" do
  class InstanceHandlerController < Monkeybars::Controller
    set_view 'RealFormTestView'
  end
  
  it "should support instance-registered callbacks" do
    callback_count = 0
    
    controller = InstanceHandlerController.instance
    controller.define_handler(:test_button_action_performed) do
      callback_count += 1
    end
    
    controller.handle_event('test_button', 'action_performed', :foo_event)
    callback_count.should == 1
  end

  it "should trigger both instance and class-level callbacks for a given event" do
    callback_count = 0
    
    class InstanceHandlerController < Monkeybars::Controller
      attr_accessor :callback_count
      def test_button_action_performed
        @callback_count += 1
      end
    end
    
    InstanceHandlerController.define_handler(:test_button_action_performed) do
      callback_count += 1
    end
    
    controller = InstanceHandlerController.instance
    controller.callback_count = 0
    
    controller.define_handler(:test_button_action_performed) do
      callback_count += 1
    end
    
    controller.instance_variable_get("@__view").get_field_value("testButton").do_click
    (callback_count + controller.callback_count).should == 3
  end
end
require 'java'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))
$CLASSPATH << File.expand_path(File.dirname(__FILE__) + "/../../lib/foxtrot.jar")

require 'monkeybars/view'
require 'monkeybars/controller'
require 'spec/unit/test_files.jar'
include_class 'java.awt.event.ActionEvent'
include_class 'java.awt.event.MouseEvent'
include_class "foxtrot.Worker"
include_class "foxtrot.Job"


class TestView < Monkeybars::View
  set_java_class 'org.monkeybars.TestView'
end

describe Monkeybars::Controller do
  
  it "allows the model and view to be set externally" do
    class TestController < Monkeybars::Controller; end
    class MyTestView; end
    class MyTestModel; end
    
    TestController.set_view "MyTestView"
    TestController.set_model "MyTestModel"
    
    TestController.send(:view_class).should == MyTestView
    TestController.send(:model_class).should == MyTestModel
  end
  
  it "allows the model and view to be overriden externally" do
    class MyTestView; end
    class MyTestModel; end
    class MyTestView2; end
    class MyTestModel2; end
    
    class TestController < Monkeybars::Controller
      set_view "MyTestView"
      set_model "MyTestModel"
    end
    
    TestController.set_view "MyTestView2"
    TestController.set_model "MyTestModel2"
    
    TestController.send(:view_class).should == MyTestView2
    TestController.send(:model_class).should == MyTestModel2
  end
end

describe "Controller instantiation" do
  before(:each) do
    Object.send(:remove_const, :TestController) if Object.const_defined? :TestController
  end
  
  it "will not create more than once instance" do
    class TestController < Monkeybars::Controller; end
    
    t = TestController.instance
    t2 = TestController.instance
    t.should equal(t2)
  end
end

describe Monkeybars::Controller, "#handle_event" do
  #mock out the post call since we're not actually running in Swing's event dispatch thread
  class Worker
    def self.post(runner)
      runner.run
    end
  end
  
  before(:each) do
    
    class HandleEventController < Monkeybars::Controller
      set_view "TestView"
      add_listener :type => :action, :components => ["testButton"]
      add_listener :type => :document, :components => ["testTextField.document"]
      
      def test_button_action_performed(event)
        $test_button_action_performed = true
      end
    end
  end
  
  it "should try to call the most specific handler available first" do
    $test_button_action_performed = false
    t = HandleEventController.instance
    target_component = t.instance_variable_get("@__view").get_field_value("testButton")
    event = ActionEvent.new(target_component, ActionEvent::ACTION_PERFORMED, "")
    t.handle_event("test_button", 'action_performed', event)
    $test_button_action_performed.should == true
    
    t.close
  end
  
  it "should call a global event handler if no specific component handler is defined"
  it "spawns a Foxtrot worker so the GUI is not blocked"
end

describe Monkeybars::Controller, "#add_handler_for" do
  
  it "does not overwrite the controller's method_missing method" do
    class AddHandlerForController < Monkeybars::Controller
      set_view "TestView"
      
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

describe Monkeybars::Controller, "#view_state" do
  
  it "returns the view's state as a model and a transfer hash" do  
    class ViewStateModel
      attr_accessor :text
      def initialize; @text= ""; end
    end
    
    class ViewStateView < Monkeybars::View
      set_java_class "org.monkeybars.TestView"
      map :view => "testTextField.text", :model => :text
      map :view => "testTextField.columns", :transfer => :text_columns
      
      def load
	testTextField.columns = 10
      end
    end
    
    class ViewStateController < Monkeybars::Controller
      set_view "ViewStateView"
      set_model "ViewStateModel"
    end
    
    t = ViewStateController.instance
    
    view_state, transfer = t.send(:view_state)
    view_state.text.should == "A text field"
    transfer[:text_columns].should == 10
    t.instance_variable_get("@__view").testTextField.text = "test data"
    t.instance_variable_get("@__view").testTextField.columns = 20
    view_state, transfer = t.send(:view_state)
    view_state.text.should == "test data"
    transfer[:text_columns].should == 20
    
    t.close
  end
end

describe Monkeybars::Controller, "#update_model" do
  
  it "updates the declared properties of the model from the view_state" do
    class UpdateModelModel; attr_accessor :text, :text2, :text3; end
    class UpdateModelController < Monkeybars::Controller; set_model "UpdateModelModel"; end
    
    t = UpdateModelController.instance
    m = UpdateModelModel.new
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
      
      def test_button_action_performed
	
      end
    end
    
    t = ImplicitRegisterController.instance
    $add_handler_called.should be_true
    t.close
  end

  it "does not add an implicit handler if an explict handler of that type was already added for that component"
  it "detects the type of the listener to use for the component when using an implicit handler"
  it "detects when a new method is added and registers a new listener if appropriate"
end

class OnedtController < Monkeybars::Controller
  attr_accessor :on_edt_called
  set_view 'TestView'
  
  def on_edt
    raise "Must be handed block" unless block_given?
    @on_edt_called = true
  end
end

module AlreadyOnEdt
  def is_on_edt
    true
  end
end

describe Monkeybars::Controller, "#signal" do
  
  it "should call on_edt to execute on the Event Dispatch Thread" do
    t = OnedtController.instance
    lambda { t.signal(:foo) }.should_not raise_error(Exception)
    t.on_edt_called.should be_true
  end
  
  it "invokes the view's process_signal method, passing along a block if given" do
    class SignalView < Monkeybars::View
      def process_signal(signal_name, model, transfer, &callback)
	raise "No block given!" unless block_given?
        raise "Incorrect signal name!" unless :signal1 == signal_name
      end
    end
    class SignalController < Monkeybars::Controller
      include AlreadyOnEdt
      set_view 'SignalView'
    end
    
    controller = SignalController.instance
    lambda {controller.signal(:signal1) {"dummy block"}}.should_not raise_error(Exception)
  end
end

describe Monkeybars::Controller, "#update_view" do
  it "should call on_edt to execute on the Event Dispatch Thread" do
    t = OnedtController.instance
    lambda { t.update_view }.should_not raise_error(Exception)
    t.on_edt_called.should be_true
  end
end

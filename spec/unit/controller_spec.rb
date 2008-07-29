require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'monkeybars/view'
require 'monkeybars/controller'
require 'spec/unit/test_files.jar'
include_class 'java.awt.event.ActionEvent'
include_class 'java.awt.event.MouseEvent'
include_class 'java.awt.event.WindowEvent'

class RealFormTestView < Monkeybars::View
  set_java_class 'org.monkeybars.TestView'
end

class EmptyTestView < Monkeybars::View; end
class EmptyTestModel; end

describe Monkeybars::Controller do
  
  it "allows the model and view to be set externally" do
    class ExternalModelSetTestController < Monkeybars::Controller; end
    
    ExternalModelSetTestController.set_view "EmptyTestView"
    ExternalModelSetTestController.set_model "EmptyTestModel"
    
    ExternalModelSetTestController.send(:view_class).should == ["EmptyTestView", nil]
    ExternalModelSetTestController.send(:model_class).should == ["EmptyTestModel", nil]
  end
  
  it "allows the model and view to be set via a block" do
    class TestBlockInitializeModel
      def initialize(string); @some_string = string; end
    end
    class ExternalModelInitializationController < Monkeybars::Controller
      attr_accessor :__view
      set_view {EmptyTestView.new}
      set_model {TestBlockInitializeModel.new("hello")}
    end
    ExternalModelInitializationController.instance.send(:model).should be_an_instance_of(TestBlockInitializeModel)
    ExternalModelInitializationController.instance.__view.should be_an_instance_of(EmptyTestView)
  end
  
  it "allows a block to be passed with set_model and set_view to be instance eval'ed" do
    class TestModel
      attr_accessor :some_value
      def initialize; @some_value = 0; end
    end
    class ExternalBlockEvalView < Monkeybars::View
      attr_accessor :some_value
      def initialize; @some_value = 0; end
    end
    class ExternalBlockEvalController < Monkeybars::Controller
      attr_accessor :__view
      set_view("ExternalBlockEvalView") { |view| view.some_value = 5 }
      set_model("TestModel") { |model| model.some_value = 5 }
    end
    ExternalBlockEvalController.instance.send(:model).some_value.should == 5
    ExternalBlockEvalController.instance.__view.some_value.should == 5
  end
  
  it "allows the model and view to be overriden externally" do
    class ExternalOverrideTestView; end
    class ExternalOverrideTestModel; end
    
    class ExternalModelOverrideTestController < Monkeybars::Controller
      set_view "EmptyTestView"
      set_model "EmptyTestModel"
    end
    
    ExternalModelOverrideTestController.set_view "ExternalOverrideTestView"
    ExternalModelOverrideTestController.set_model "ExternalOverrideTestModel"
    
    ExternalModelOverrideTestController.send(:view_class).should == ["ExternalOverrideTestView", nil]
    ExternalModelOverrideTestController.send(:model_class).should == ["ExternalOverrideTestModel", nil]
  end
  
  it "updates the correct instance on Controller#update" do
    class MultipleInstanceUpdateController < Monkeybars::Controller
      set_update_method :tick
      
      def tick
        object_id
      end
    end
    
    begin
      instance1 = MultipleInstanceUpdateController.create_instance
      instance2 = MultipleInstanceUpdateController.create_instance

      instance1.update.should_not == instance2.update
    ensure
      MultipleInstanceUpdateController.destroy_instance instance1
      MultipleInstanceUpdateController.destroy_instance instance2
    end
  end
end

describe "Controller instantiation" do
  it "will not create more than once instance" do
    class SingleInstanceController < Monkeybars::Controller; end
    
    t = SingleInstanceController.instance
    t2 = SingleInstanceController.instance
    t.should equal(t2)
  end
  
  it "puts only one instance in the listance list per create_instance call" do
    class MultipleInstanceController < Monkeybars::Controller; end
    
    #ensure initial value is zero
    Monkeybars::Controller.send(:class_variable_get, :@@instance_list)[MultipleInstanceController].size.should be_zero
    
    begin
      instance = MultipleInstanceController.create_instance
      Monkeybars::Controller.send(:class_variable_get, :@@instance_list)[MultipleInstanceController].size.should == 1
    ensure
      MultipleInstanceController.destroy_instance instance
    end
  end
end

describe Monkeybars::Controller, ' nesting' do
  class OuterController < Monkeybars::Controller; end
  
  it "invokes controller group's nesting#add on add_nested_controller" do
    controller = OuterController.instance
    controller.stub! :model
    controller.stub! :transfer
    view = mock("view")
    view.should_receive :add_nested_view
    controller.instance_variable_set(:@__view, view)
    
    foo_component = mock("foo_component")
    
    foo_view = mock("foo_view")
    foo_view.instance_variable_set(:@main_view_component, foo_component)
    
    foo_controller = mock("foo_controller")
    foo_controller.instance_variable_set(:@__view, foo_view)
    
    controller.add_nested_controller :foo, foo_controller
  end
  
  it "invokes controller group's nesting#remove on remove_nested_controller" do
    controller = OuterController.instance
    controller.stub! :model
    controller.stub! :transfer
    view = mock("view")
    view.should_receive :remove_nested_view
    controller.instance_variable_set(:@__view, view)
    
    foo_component = mock("foo_component")
    
    foo_view = mock("foo_view")
    foo_view.instance_variable_set(:@main_view_component, foo_component)
    
    foo_controller = mock("foo_controller")
    foo_controller.instance_variable_set(:@__view, foo_view)
    
    controller.remove_nested_controller :foo, foo_controller
  end
end

describe Monkeybars::Controller, "#view_state" do
  
  it "returns the view's state as a ViewState object" do  
    class ReturnsViewStateModel
      attr_accessor :text
      def initialize; @text= ""; end
    end
    
    class ReturnsViewStateView < Monkeybars::View
      set_java_class "org.monkeybars.TestView"
      map :view => "testTextField.text", :model => :text
      map :view => "testTextField.columns", :transfer => :text_columns
      
      def load
	testTextField.columns = 10
      end
    end
    
    class ReturnsViewStateController < Monkeybars::Controller
      set_view "ReturnsViewStateView"
      set_model "ReturnsViewStateModel"
    end
    
    t = ReturnsViewStateController.instance
    
    view_state = t.send(:view_state)
    view_state.class.should == Monkeybars::ViewState
    view_state.model.text.should == "A text field"
    view_state.transfer[:text_columns].should == 10
    
    t.close
  end
  
  it "memoizes the value of the view state" do
    class MemoizesViewStateModel
      attr_accessor :text
      def initialize; @text= ""; end
    end
    
    class MemoizesViewStateView < Monkeybars::View
      set_java_class "org.monkeybars.TestView"
      map :view => "testTextField.text", :model => :text
      map :view => "testTextField.columns", :transfer => :text_columns
      
      def load
	testTextField.columns = 10
      end
    end
    
    class MemoizesViewStateController < Monkeybars::Controller
      set_view "MemoizesViewStateView"
      set_model "MemoizesViewStateModel"
    end
    
    t = MemoizesViewStateController.instance
    view_state = t.send(:view_state)
    view_state.should be_equal(t.send(:view_state))
    
    t.instance_variable_get("@__view").testTextField.text = "test data"
    t.instance_variable_get("@__view").testTextField.columns = 20
    
    view_state.should be_equal(t.send(:view_state))
  end
end

describe Monkeybars::Controller, "#update_model" do
  
  it "updates the declared properties of the model from the view_state" do
    class UpdateModelModel; attr_accessor :text, :text2, :text3; end
    class UpdateModelController < Monkeybars::Controller; set_model "UpdateModelModel"; end
    
    t = UpdateModelController.instance
    m = UpdateModelModel.new
    m.text = "some test data1"
    m.text2 = "some test data2"
    m.text3 = "some test data3"
    
    t.send(:model).text = ""
    t.send(:model).text2 = ""
    t.send(:model).text2 = ""
    t.send(:update_model, m, :text, :text3)
    t.send(:model).text.should == "some test data1"
    t.send(:model).text2.should == ""
    t.send(:model).text3.should == "some test data3"
    t.close
  end
end

describe Monkeybars::Controller, "#update_provided_model" do
  c = Monkeybars::Controller.instance
  class TestUpdateProvidedModel; attr_accessor :attr1, :attr2, :attr3; end
  
  t1 = TestUpdateProvidedModel.new
  t2 = TestUpdateProvidedModel.new
  
  t1.attr1 = 10
  t1.attr2 = "foo"
  t1.attr3 = (1..10)
  
  c.send(:update_provided_model, t1, t2, :attr1, :attr2, :attr3)
  t2.attr1.should == 10
  t2.attr2.should == "foo"
  t2.attr3.should == (1..10)
end

describe Monkeybars::Controller, "#signal" do
  
  it "invokes the view's process_signal method, passing along a block if given" do
    class SignalView < Monkeybars::View
      def process_signal(signal_name, model, transfer, &callback)
	raise "No block given!" unless block_given?
        raise "Incorrect signal name!" unless :signal1 == signal_name
      end
    end
    class SignalController < Monkeybars::Controller
      set_view 'SignalView'
    end
    
    controller = SignalController.instance
    lambda {controller.signal(:signal1) {"dummy block"}}.should_not raise_error(Exception)
  end
end

describe Monkeybars::Controller, "closing the controller" do
  
  module Monkeybars
    class Controller
      def self.cleanup_instances
        class_variable_get(:@@instance_list).clear
      end
    end
  end
  
  before(:each) { Monkeybars::Controller::cleanup_instances }
  
  class ClosingTestView < Monkeybars::View
    set_java_class 'org.monkeybars.TestView'
    def close
      java_window.process_window_event WindowEvent.new(java_window, WindowEvent::WINDOW_CLOSING)
    end
  end

  class ClosingController < Monkeybars::Controller
    set_view 'ClosingTestView'
  end
  
  class AnotherClosingController < Monkeybars::Controller
    set_view 'ClosingTestView'
  end
  

  def close_controller_test_case(close_action = nil)
    ClosingController.set_close_action(close_action) unless close_action.nil?
    controller = ClosingController.instance
    view = controller.instance_variable_get("@__view")
    yield controller, view
    view.close
  end
  
  it "should trigger unload if no close action is specified" do
    close_controller_test_case do |controller, view| # default
      controller.should_receive :unload
      view.should_receive :unload
      view.should_receive :dispose
    end
  end
  
  it "should should trigger unload if :close action is specified" do
    close_controller_test_case :close do |controller, view|
      controller.should_receive :unload
      view.should_receive :unload
      view.should_receive :dispose
    end
  end
  
  it "should should trigger unload on all controllers if :exit action is specified and the system should exit" do
    close_controller_test_case :exit do |controller, view|
      expectations = lambda {|c, v|
        c.should_receive :unload
        v.should_receive :unload
        v.should_receive :dispose
      }
      expectations.call(controller, view)
      
      another_controller = AnotherClosingController.instance
      another_view = another_controller.instance_variable_get("@__view")
      expectations.call(another_controller, another_view)

      java.lang.System.should_receive :exit
    end
  end
  
  it "should not trigger unload when the controller is configured with :nothing action" do
    close_controller_test_case :nothing do |controller, view|
      controller.should_not_receive :unload
      view.should_not_receive :unload
    end
  end

  it "should not trigger unload when the controller is configured with :dispose action but the view should be disposed" do
    close_controller_test_case(:dispose) do |controller, view|
      controller.should_not_receive :unload
      view.should_receive :dispose
    end
  end

  it "should not trigger unload when the controller is configured with :hide action but the view should be hidden" do
    close_controller_test_case(:hide) do |controller, view|
      controller.should_not_receive :unload
      view.should_receive :hide
    end
  end
end
require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'monkeybars/view'
require 'monkeybars/controller'
require 'spec/unit/test_files.jar'

class TestingView < Monkeybars::View
  set_java_class 'org.monkeybars.TestView'
end

describe Monkeybars::View, ".nest" do
  it 'creates a Nesting object for this subclass' do
    TestingView.nest :sub_view => :foo , :view => :bar
    TestingView.send(:view_nestings)[:foo].size.should > 0
  end
end

describe Monkeybars::View, ".define_signal" do
  begin
    class DefineSignalTest < Monkeybars::View
      define_signal :name => :signal_name, :handler => :handler_name
    end
  rescue => e
    puts "unexpected error in DefineSignalTest"
    puts e
    puts e.backtrace
  end

  it "produces a handler name from a signal name (REWRITE: Implementation)" do
    DefineSignalTest.send(:signal_mappings)[:signal_name].should == :handler_name
  end

  it "does not raise an error when only :name and :handler are given options" do
    lambda {DefineSignalTest.define_signal :name => :test_name, :handler => :test_handler}.should_not raise_error(InvalidSignalError)
  end

  it "raises an error when anything other than both :name and :handler are given options" do
    lambda {DefineSignalTest.define_signal :name => :test_name, :handler => :test_handler, :other => :other_test}.should raise_error(InvalidSignalError)
    lambda {DefineSignalTest.define_signal :name => :test_name}.should raise_error(InvalidSignalError)
    lambda {DefineSignalTest.define_signal :name => :test_handler}.should raise_error(InvalidSignalError)
    lambda {DefineSignalTest.define_signal :handler => :test_handler}.should raise_error(InvalidSignalError)
    lambda {DefineSignalTest.define_signal Hash.new}.should raise_error(InvalidSignalError)
  end
end

describe Monkeybars::View, "#get_field_value" do
  before(:each) do
    @view = TestingView.new
  end

  after(:each) do
    #Make swing threads go away so test can exit
    @view.instance_variable_get("@main_view_component").dispose
  end
  
  it "should return a reference to the java field's value" do
    @view.send(:get_field_value, :test_label).text.should == "A Test Label"
    @view.send(:get_field_value, :test_label).text = "New Label"
    @view.send(:get_field_value, :test_label).text.should == "New Label"
  end
  
  it "can return a reference to a primitive field" do
    @view.send(:get_field_value, :primitive_variable).should == 20
    @view.send(:get_field_value, :object_variable).should == 30
  end
  
  it "returns same reference on subsequent calls" do
    
    label = @view.send(:get_field_value, :test_label)
    label2 = @view.send(:get_field_value, :test_label)
    label.should equal(label2)
  end
end

describe Monkeybars::View, "#get_field" do
  after(:each) do
    #Make swing threads go away so test can exit
    @view.instance_variable_get("@main_view_component").dispose
  end
  
  it "uses cached reference to a field if it is available" do
    @view = TestingView.new
    @view.instance_variable_get(:@__field_references)[:test_label] = "test data instead of an actual field"
    @view.send(:get_field, :test_label).should == "test data instead of an actual field"
  end
  
  it "allows field references to be updated when called with =" do
    class ReplaceComponentView < Monkeybars::View
      set_java_class 'org.monkeybars.TestView'
      
      def replace_test_button
        self.test_button = javax.swing.JButton.new("New button text")
      end
      
      def test_button_text
	test_button.text
      end
    end
    
    @view = ReplaceComponentView.new
    puts "@main_view_component: #{@view.instance_variable_get("@main_view_component")}"
    @view.replace_test_button
    @view.test_button_text.should == "New button text"
    
  end
end

describe Monkeybars::View, "#add_handler" do
  it "can resolve nested components" do
    view = TestingView.new
    lambda {view.add_handler(Monkeybars::DocumentHandler.new(self, :document), "testTextField.some_made_up_name")}.should raise_error(Monkeybars::UndefinedControlError)
    lambda {view.add_handler(Monkeybars::DocumentHandler.new(self, :document), "testTextField.document")}.should_not raise_error(Monkeybars::UndefinedControlError)
    
    view.instance_variable_get("@main_view_component").dispose
  end
end

describe Monkeybars::View, "#validate_mapping" do
  it "identifies mappings as in-only, out-only, or bi-directional"
  it "detects mis-named methods declared in a mapping"
end

describe Monkeybars::View, "#update" do
  it "only invokes mappings with direction to view or both" do
    class InvokeMappingToView < Monkeybars::View; end
    view = InvokeMappingToView.new

    mock_mappings = Array.new(5) { |i| mock("Mapping#{i}", :from_view => nil)}
    mock_mappings[0].should_receive(:maps_to_view?).and_return(true)
    mock_mappings[0].should_receive(:to_view).once
    mock_mappings[1].should_receive(:maps_to_view?).and_return(true)
    mock_mappings[1].should_receive(:to_view).once
    mock_mappings[2].should_receive(:maps_to_view?).and_return(false)
    mock_mappings[2].should_not_receive(:to_view)
    mock_mappings[3].should_receive(:maps_to_view?).and_return(false)
    mock_mappings[3].should_not_receive(:to_view)
    mock_mappings[4].should_receive(:maps_to_view?).and_return(false)
    mock_mappings[4].should_not_receive(:to_view)
    
    InvokeMappingToView.should_receive(:view_mappings).and_return(mock_mappings)
    
    view.update(nil, {})
  end
end

describe Monkeybars::View, "#write_state" do
  it "only invokes mappings with direction from view or both" do
    class InvokeMappingFromView < Monkeybars::View; end
    view = InvokeMappingFromView.new

    mock_mappings = Array.new(5) { |i| mock("Mapping#{i}", :from_view => nil)}
    mock_mappings[0].should_receive(:maps_from_view?).and_return(true)
    mock_mappings[0].should_receive(:from_view).once
    mock_mappings[1].should_receive(:maps_from_view?).and_return(true)
    mock_mappings[1].should_receive(:from_view).once
    mock_mappings[2].should_receive(:maps_from_view?).and_return(false)
    mock_mappings[2].should_not_receive(:from_view)
    mock_mappings[3].should_receive(:maps_from_view?).and_return(false)
    mock_mappings[3].should_not_receive(:from_view)
    mock_mappings[4].should_receive(:maps_from_view?).and_return(false)
    mock_mappings[4].should_not_receive(:from_view)
    
    InvokeMappingFromView.should_receive(:view_mappings).and_return(mock_mappings)
    
    view.write_state(nil, {})
  end
end

describe Monkeybars::View, "#process_signal" do
  class BasicSignalHandler < Monkeybars::View
    define_signal :signal1, :handler
  end  

  class ProcessSignalView < Monkeybars::View
    define_signal :signal1, :handler

    def handler(model, transfer)
      raise Exception unless block_given?
    end
  end

  it "invokes a UndefinedSignalError when it recieves a signal that is not declared" do
    view = Monkeybars::View.new
    lambda {view.process_signal(:signal_that_is_not_defined, nil, nil)}.should raise_error(Monkeybars::UndefinedSignalError)
  end
  
  it "invokes a InvalidSignalHandlerError when the declared signal's handler method does not exist" do
    view = BasicSignalHandler.new
    lambda{view.process_signal(:signal1, nil, nil)}.should raise_error(Monkeybars::InvalidSignalHandlerError)
  end
  
  it "invokes the mapped method when a signal is received" do
    view = BasicSignalHandler.new
    view.should_receive(:handler)
    view.process_signal(:signal1, nil, nil)
  end
  
  it "invokes the method associated with the signal when called and passes along any block passed to it" do
    view = ProcessSignalView.new
    lambda {view.process_signal(:signal1, nil, nil) {"this is a dummy block"}}.should_not raise_error(Exception)
  end
end
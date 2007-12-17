$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'java'
require 'monkeybars/view'

describe "view's map method" do
  before(:each) do
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
  end
  
  it "only accepts :view, :model, :using and :ignoring as hash parameters" do
    
    lambda {
      class TestView < Monkeybars::View
        map :view => :view_field, :model => :model_field, :using => [:from_model, :to_model], :ignoring => [:item]
      end
    }.should_not raise_error(InvalidHashKeyError)
    
    Object.send(:remove_const, :TestView)
    
    lambda {
      class TestView < Monkeybars::View
        map :foo => nil, :bar => nil
      end
    }.should raise_error(InvalidHashKeyError)
  end  
end


describe "View's map and raw_mapping methods" do
  before(:each) do
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
  end
  
  it "accepts symbols for both view and model attributes" do
    class TestView < Monkeybars::View
      map :view => :view_field, :model => :model_field
    end
    
    lambda {TestView.new}.should_not raise_error(ArgumentError)
  end
  
  it "accepts strings for both view and model attributes" do
    class TestView < Monkeybars::View
      map :view => "view_field", :model => "model_field"
    end
    
    lambda {TestView.new}.should_not raise_error(ArgumentError)
  end
  
  it "can accept a string for nested properties for both the view and the model" do
    class TestView < Monkeybars::View
      map :view => "view_field.property", :model => "model_field.property"
    end
    
    lambda {TestView.new}.should_not raise_error(ArgumentError)
  end
  
  it "creates a ModelMapping object for each map declaration" do
    class TestView < Monkeybars::View
      map :view => "view_field.property", :model => "model_field.property"
    end
    
    (TestView.send(:view_mappings).size).should == 1
    
    Object.send(:remove_const, :TestView)
    
    class TestView < Monkeybars::View
      map :view => "view_field.property", :model => "model_field.property1"
      map :view => "view_field.property", :model => "model_field.property2"
      map :view => "view_field.property", :model => "model_field.property3"
      map :view => "view_field.property", :model => "model_field.property4"
    end
    
    (TestView.send(:view_mappings).size).should == 4
  end
  
  it "creates a ModelMapping object for each raw_mapping declaration" do
    class TestView < Monkeybars::View
      raw_mapping(:in_method, :to_model_method)
    end
    
    (TestView.send(:view_mappings).size).should == 1
    
    Object.send(:remove_const, :TestView)
    
    class TestView < Monkeybars::View
      raw_mapping :from_model_method1, :to_model_method1
      raw_mapping :from_model_method2, :to_model_method2
      map :view => :view_field, :model => :model_field
    end
    
    (TestView.send(:view_mappings).size).should == 3
  end
  
  it "allows more than one level of subclassing" do
    class BaseView < Monkeybars::View; end
    class TestView < BaseView
      map :view => "view_field.property", :model => "model_field.property"
    end
    
    (TestView.send(:view_mappings).size).should == 1
  end
end

describe "validate_mappings method" do
  before(:each) do
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
  end
  
  it "sets direction to both when only properties are provided" do
    class TestView < Monkeybars::View
      map :view => :foo, :model => :bar
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_BOTH
  end
  
  it "sets direction to from_model when only 'from_model' methods are provided" do
    class TestView < Monkeybars::View
      map :view => :foo, :model => :bar, :using => [:method1, nil]
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_FROM_MODEL
  end
  
  it "sets direction to to_model when only 'to_model' methods are provided" do
    class TestView < Monkeybars::View
      map :view => :foo, :model => :bar, :using => [nil, :method1]
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_TO_MODEL
  end
  
  it "sets direction to both when both methods are provided" do
    class TestView < Monkeybars::View
      map :view => :foo, :model => :bar, :using => [:method1, :method1]
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_BOTH
  end
  
  it "sets direction to from_model when only 'from_model' raw method is provided" do
    class TestView < Monkeybars::View
      raw_mapping :method1, nil
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_FROM_MODEL
  end

  it "sets direction to to_model when only 'to_model' raw method is provided" do
    class TestView < Monkeybars::View
      raw_mapping nil, :method1
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_TO_MODEL
  end
  
  it "sets direction to both when both raw methods are provided" do
    class TestView < Monkeybars::View
      raw_mapping :method1, :method1
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_BOTH
  end
  
  it "sets type to properties when only :model and :view are provided" do
    class TestView < Monkeybars::View
      map :view => :foo, :model => :bar
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_PROPERTIES
  end
  
  it "sets type to method when :model, :view, and :using are used" do
    class TestView < Monkeybars::View
      map :view => :foo, :model => :bar, :using => [:method1, nil]
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_METHOD
    
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    class TestView < Monkeybars::View
      map :view => :foo, :model => :bar, :using => [:method1, nil]
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_METHOD
    
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    class TestView < Monkeybars::View
      map :view => :foo, :model => :bar, :using => [:method1, :method1]
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_METHOD
  end
  
  it "sets type to raw when raw_method() is used" do
    class TestView < Monkeybars::View
      raw_mapping :method1, nil
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_RAW
    
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    class TestView < Monkeybars::View
      raw_mapping nil, :method1
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_RAW
    
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    class TestView < Monkeybars::View
      raw_mapping :method1, :method1
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_RAW
  end
  
  it "parameter mapping requires both a view and model parameter" do
    class TestView < Monkeybars::View
      map :view => :foo
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
    
    Object.send(:remove_const, :TestView)
    class TestView < Monkeybars::View
      map :view => :foo, :model => nil
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
    
    Object.send(:remove_const, :TestView)
    class TestView < Monkeybars::View
      map({})
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
    
    Object.send(:remove_const, :TestView)
    class TestView < Monkeybars::View
      map :view => nil, :model => :foo
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
  end
  
  it "mapping via methods requires both a view and model parameter" do
    class TestView < Monkeybars::View
      map :view => nil, :model => :bar, :using => [:method1, nil]
      
      def method1; end
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
    
    Object.send(:remove_const, :TestView)
    class TestView < Monkeybars::View
      map :view => :foo, :model => nil, :using => [:method1, nil]
      
      def method1; end
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
  end
  
  it "throws exception when 'from_model' method doesn't exist" do
    class TestView < Monkeybars::View
        attr_accessor :view_field
        map :view => :view_field, :model => :ignored_when_mapping_from_model_to_view, :using => [:non_existant_method, nil]
    end
    
    lambda {TestView.new}.should raise_error(InvalidMappingError)
  end

  it "throws exception when 'to_model' method doesn't exist" do
    class TestView < Monkeybars::View
        attr_accessor :view_field
        map :view => :view_field, :model => :ignored_when_mapping_from_model_to_view, :using => [nil, :non_existant_method]
    end
    
    lambda {TestView.new}.should raise_error(InvalidMappingError)
  end
end

describe "update_from_model method" do
  before(:each) do
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    Object.send(:remove_const, :Model) if Object.const_defined? :Model
  end
  
  it "parses view and method properties (as symbols) from ModelMapping data" do
    class TestView < Monkeybars::View
      map :view => :view_field, :model => :model_field
      attr_accessor :view_field
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    model.model_field = 10
    view.update_from_model(model)
    view.view_field.should == 10
    
    model.model_field = "test string"
    view.update_from_model(model)
    view.view_field.should == "test string"
  end
  
  it "parses view and method properties (as strings) from ModelMapping data" do
    class TestView < Monkeybars::View
      map :view => "view_field", :model => "model_field"
      attr_accessor :view_field
    end
    
    class Model
      attr_accessor :model_field
    end
  
    view = TestView.new
    model = Model.new
    
    model.model_field = 10
    view.update_from_model(model)
    view.view_field.should == 10
    
    model.model_field = "string assigned to single level property"
    view.update_from_model(model)
    view.view_field.should == "string assigned to single level property"
  end
  
  it "parses nested view and method properties from ModelMapping data" do
    class TestView < Monkeybars::View
      attr_accessor :view_field
      Struct.new("View", :sub_field)
      
      map :view => "view_field.sub_field", :model => "model_field.sub_field"
      
      def load
        @view_field = Struct::View.new
      end
    end
    
    class Model
      attr_accessor :model_field
      Struct.new("Model", :sub_field)
      
      def initialize
        @model_field = Struct::Model.new
      end
    end
    
    view = TestView.new
    
    model = Model.new
    
    model.model_field.sub_field = 42
    view.update_from_model(model)
    view.view_field.sub_field.should == 42
    
    model.model_field.sub_field = "string assigned to a nested property"
    view.update_from_model(model)
    view.view_field.sub_field.should == "string assigned to a nested property"
  end
  
  it "invokes 'from_model' method when specified" do
    class TestView < Monkeybars::View
      attr_accessor :view_field
      map :view => :view_field, :model => :ignored_when_mapping_from_model_to_view, :using => [:view_field_from_model_method, nil]
      
      def view_field_from_model_method(model)
        model.model_field + " plus text from the method"
      end
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    model.model_field = "value to be assigned to view_field"
    view.update_from_model(model)
    view.view_field.should == "value to be assigned to view_field plus text from the method"
  end
  
  it "invokes raw_mapping 'from_model' method when specified" do
    class TestView < Monkeybars::View
      raw_mapping :from_model_method, nil
      attr_accessor :view_field
      
      def from_model_method(model)
        self.view_field = model.model_field * 10
      end
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    model.model_field = 4
    view.update_from_model(model)
    view.view_field.should == 40
    
    model.model_field = "a"
    view.update_from_model(model)
    view.view_field.should == "aaaaaaaaaa"
  end
  
  it "reads correct view mappings when subclassed by more than one level" do
    class Model
      attr_accessor :model_property
    end
    
    class BaseView < Monkeybars::View; end
    class TestView < BaseView
      attr_accessor :property
      map :view => "property", :model => "model_property"
    end
    
    m = Model.new
    m.model_property = "test string"
    
    t = TestView.new
    t.update_from_model(m)
    t.property.should == "test string"
  end
  
  it "uses normal property mapping when :default is given as 'from_model' method" do
    class Model
      attr_accessor :model_property
    end
    
    class TestView < Monkeybars::View
      attr_accessor :view_property
      map :view => :view_property, :model => :model_property, :using => [:default, :default]
    end
    
    m = Model.new
    m.model_property = "model property string"
    v = TestView.new
    v.update_from_model(m)
    v.view_property.should == "model property string"
  end
  
  it "ignores handlers when .ignoring is used"
end

describe "write_state_to_model method" do
  before(:each) do
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
  end
  
  it "parses view and method properties (as symbols) from ModelMapping data" do
    class TestView < Monkeybars::View
      map :view => :view_field, :model => :model_field
      attr_accessor :view_field
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    view.view_field = 7
    view.write_state_to_model(model)
    model.model_field.should == 7
    
    view.view_field = "string assigned to view property"
    view.write_state_to_model(model)
    model.model_field.should == "string assigned to view property"
  end
  
  it "parses view and method properties (as strings) from ModelMapping data" do
    class TestView < Monkeybars::View
      map :view => "view_field", :model => "model_field"
      attr_accessor :view_field
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    view.view_field = 7
    view.write_state_to_model(model)
    model.model_field.should == 7
    
    view.view_field = "string assigned to view property"
    view.write_state_to_model(model)
    model.model_field.should == "string assigned to view property"
  end
  
  it "parses nested view and method properties from ModelMapping data" do
    class TestView < Monkeybars::View
      attr_accessor :view_field
      Struct.new("View2", :sub_field)
      
      map :view => "view_field.sub_field", :model => "model_field.sub_field"
      
      def load
        @view_field = Struct::View2.new
      end
    end
    
    class Model
      attr_accessor :model_field
      Struct.new("Model2", :sub_field)
      
      def initialize
        @model_field = Struct::Model2.new
      end
    end
    
    view = TestView.new
    model = Model.new
    
    view.view_field.sub_field = 42
    view.write_state_to_model(model)
    model.model_field.sub_field .should == 42
    
    view.view_field.sub_field = "string assigned to a nested property"
    view.write_state_to_model(model)
    model.model_field.sub_field.should == "string assigned to a nested property"
  end
  
  it "invokes 'to_model' method when specified" do
    class TestView < Monkeybars::View
      map :view => "view_field", :model => "model_field", :using => [nil, :method1]
      attr_accessor :view_field
      
      def method1(model)
        view_field * 10
      end
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    view.view_field = 7
    view.write_state_to_model(model)
    model.model_field.should == 70
    
    view.view_field = "ha"
    view.write_state_to_model(model)
    model.model_field.should == "hahahahahahahahahaha"
  end
  
  it "invokes raw_mapping 'to_model' method when specified" do
    class TestView < Monkeybars::View
      raw_mapping nil, :method1
      attr_accessor :view_field
      
      def method1(model)
        model.model_field = "here you go: #{view_field}"
      end
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    view.view_field = 99
    view.write_state_to_model(model)
    model.model_field.should == "here you go: 99"
    
    view.view_field = "text!"
    view.write_state_to_model(model)
    model.model_field.should == "here you go: text!"
  end
  
  it "uses normal property mapping when :default is given as 'to_model' method" do
    class Model
      attr_accessor :model_property
    end
    
    class TestView < Monkeybars::View
      attr_accessor :view_property
      map :view => :view_property, :model => :model_property, :using => [:default, :default]
    end
    
    view = TestView.new
    view.view_property = "some amazingly awesome view data"
    model = Model.new
    
    view.write_state_to_model(model)
    model.model_property.should == "some amazingly awesome view data"
  end
  
  it "ignores handlers when .ignoring is used"
end
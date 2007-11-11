$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'java'
require 'monkeybars/view'

describe "map(), to(), using() and raw_mapping() methods" do
  before(:each) do
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
  end
  
  it "accepts symbols for both view and model attributes" do
    class TestView < Monkeybars::View
      map(:view_field).to(:model_field)
    end
    
    lambda {TestView.new}.should_not raise_error(ArgumentError)
  end
  
  it "accepts strings for both view and model attributes" do
    class TestView < Monkeybars::View
      map("view_field").to("model_field")
    end
    
    lambda {TestView.new}.should_not raise_error(ArgumentError)
  end
  
  it "can accept a string for nested properties for both the view and the model" do
    class TestView < Monkeybars::View
      map("view_field.property").to("model_field.property")
    end
    
    lambda {TestView.new}.should_not raise_error(ArgumentError)
  end
  
  it "creates a ModelMapping object for each map declaration" do
    class TestView < Monkeybars::View
      map("view_field.property").to("model_field.property")
    end
    
    (TestView.send(:view_mappings).size).should == 1
    
    Object.send(:remove_const, :TestView)
    
    class TestView < Monkeybars::View
      map("view_field.property1").to("model_field.property1")
      map("view_field.property2").to("model_field.property2")
      map("view_field.property3").to("model_field.property3")
      map("view_field.property4").to("model_field.property4")
    end
    
    (TestView.send(:view_mappings).size).should == 4
  end
  
  it "creates a ModelMapping object for each raw_mapping declaration" do
    class TestView < Monkeybars::View
      raw_mapping(:in_method, :out_method)
    end
    
    (TestView.send(:view_mappings).size).should == 1
    
    Object.send(:remove_const, :TestView)
    
    class TestView < Monkeybars::View
      raw_mapping(:in_method1, :out_method1)
      raw_mapping(:in_method2, :out_method2)
      map(:view_field).to(:model_field)
    end
    
    (TestView.send(:view_mappings).size).should == 3
  end
  
  it "allows more than one level of subclassing" do
    class BaseView < Monkeybars::View; end
    class TestView < BaseView
      map("view_field.property").to("model_field.property")
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
      map(:foo).to(:bar)
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_BOTH
  end
  
  it "sets direction to in when only 'in' methods are provided" do
    class TestView < Monkeybars::View
      map(:foo).to(:bar).using(:method1, nil)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_IN
  end
  
  it "sets direction to out when only 'out' methods are provided" do
    class TestView < Monkeybars::View
      map(:foo).to(:bar).using(nil, :method1)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_OUT
  end
  
  it "sets direction to both when both methods are provided" do
    class TestView < Monkeybars::View
      map(:foo).to(:bar).using(:method1, :method1)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_BOTH
  end
  
  it "sets direction to in when only 'in' raw method is provided" do
    class TestView < Monkeybars::View
      raw_mapping(:method1, nil)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_IN
  end

  it "sets direction to out when only 'out' raw method is provided" do
    class TestView < Monkeybars::View
      raw_mapping(nil, :method1)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_OUT
  end
  
  it "sets direction to both when both raw methods are provided" do
    class TestView < Monkeybars::View
      raw_mapping(:method1, :method1)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].direction.should == Monkeybars::View::ModelMapping::DIRECTION_BOTH
  end
  
  it "sets type to properties when only map().to() is used" do
    class TestView < Monkeybars::View
      map(:foo).to(:bar)
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_PROPERTIES
  end
  
  it "sets type to method when map().to().method() is used" do
    class TestView < Monkeybars::View
      map(:foo).to(:bar).using(:method1, nil)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_METHOD
    
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    class TestView < Monkeybars::View
      map(:foo).to(:bar).using(nil, :method1)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_METHOD
    
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    class TestView < Monkeybars::View
      map(:foo).to(:bar).using(:method1, :method1)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_METHOD
  end
  
  it "sets type to raw when raw_method() is used" do
    class TestView < Monkeybars::View
      raw_mapping(:method1, nil)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_RAW
    
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    class TestView < Monkeybars::View
      raw_mapping(nil, :method1)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_RAW
    
    Object.send(:remove_const, :TestView) if Object.const_defined? :TestView
    class TestView < Monkeybars::View
      raw_mapping(:method1, :method1)
      def method1; end
    end
    
    TestView.new.send(:instance_variable_get, :@__valid_mappings)[0].type.should == Monkeybars::View::ModelMapping::TYPE_RAW
  end
  
  it "parameter mapping requires both a view and model parameter" do
    class TestView < Monkeybars::View
      map(:foo)
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
    
    Object.send(:remove_const, :TestView)
    class TestView < Monkeybars::View
      map(:foo).to(nil)
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
    
    Object.send(:remove_const, :TestView)
    class TestView < Monkeybars::View
      map(nil)
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
    
    Object.send(:remove_const, :TestView)
    class TestView < Monkeybars::View
      map(nil).to(:foo)
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
  end
  
  it "mapping via methods requires both a view and model parameter" do
    class TestView < Monkeybars::View
      map(nil).to(:bar).using(:method1, nil)
      
      def method1; end
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
    
    Object.send(:remove_const, :TestView)
    class TestView < Monkeybars::View
      map(:foo).to(nil).using(:method1, nil)
      
      def method1; end
    end
    lambda {TestView.new}.should raise_error(InvalidMappingError)
  end
  
  it "throws exception when 'in' method doesn't exist" do
    class TestView < Monkeybars::View
        attr_accessor :view_field
        map(:view_field).to(:ignored_when_mapping_from_model_to_view).using(:non_existant_method, nil)
    end
    
    lambda {TestView.new}.should raise_error(InvalidMappingError)
  end

  it "throws exception when 'out' method doesn't exist" do
    class TestView < Monkeybars::View
        attr_accessor :view_field
        map(:view_field).to(:ignored_when_mapping_from_model_to_view).using(nil, :non_existant_method)
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
      map(:view_field).to(:model_field)
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
      map("view_field").to("model_field")
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
      
      map("view_field.sub_field").to("model_field.sub_field")
      
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
  
  it "invokes 'in' method when specified" do
    class TestView < Monkeybars::View
      attr_accessor :view_field
      map(:view_field).to(:ignored_when_mapping_from_model_to_view).using(:view_field_in_method, nil)
      
      def view_field_in_method(model)
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
  
  it "invokes raw_mapping 'in' method when specified" do
    class TestView < Monkeybars::View
      raw_mapping(:in_method, nil)
      attr_accessor :view_field
      
      def in_method(model)
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
      map("property").to("model_property")
    end
    
    m = Model.new
    m.model_property = "test string"
    
    t = TestView.new
    t.update_from_model(m)
    t.property.should == "test string"
  end
  
  it "uses normal property mapping when :default is given as 'in' method" do
    class Model
      attr_accessor :model_property
    end
    
    class TestView < Monkeybars::View
      attr_accessor :view_property
      map(:view_property).to(:model_property).using(:default, :default)
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
      map(:view_field).to(:model_field)
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
      map("view_field").to("model_field")
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
      
      map("view_field.sub_field").to("model_field.sub_field")
      
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
  
  it "invokes 'out' method when specified" do
    class TestView < Monkeybars::View
      map("view_field").to("model_field").using(nil, :method1)
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
  
  it "invokes raw_mapping 'out' method when specified" do
    class TestView < Monkeybars::View
      raw_mapping(nil, :method1)
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
  
  it "uses normal property mapping when :default is given as 'out' method" do
    class Model
      attr_accessor :model_property
    end
    
    class TestView < Monkeybars::View
      attr_accessor :view_property
      map(:view_property).to(:model_property).using(:default, :default)
    end
    
    view = TestView.new
    view.view_property = "some amazingly awesome view data"
    model = Model.new
    
    view.write_state_to_model(model)
    model.model_property.should == "some amazingly awesome view data"
  end
  
  it "ignores handlers when .ignoring is used"
end
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'java'
require 'monkeybars/view'

describe "update method" do
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
    view.update(model, {})
    view.view_field.should == 10
    
    model.model_field = "test string"
    view.update(model, {})
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
    view.update(model, {})
    view.view_field.should == 10
    
    model.model_field = "string assigned to single level property"
    view.update(model, {})
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
    view.update(model, {})
    view.view_field.sub_field.should == 42
    
    model.model_field.sub_field = "string assigned to a nested property"
    view.update(model, {})
    view.view_field.sub_field.should == "string assigned to a nested property"
  end
  
  it "invokes 'from_model' method when specified" do
    class TestView < Monkeybars::View
      attr_accessor :view_field
      map :view => :view_field, :model => :model_field, :using => [:view_field_from_model_method, nil]
      
      def view_field_from_model_method(model_field)
        model_field + " plus text from the method"
      end
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    model.model_field = "value to be assigned to view_field"
    view.update(model, {})
    view.view_field.should == "value to be assigned to view_field plus text from the method"
  end
  
  it "invokes raw_mapping 'from_model' method when specified" do
    class TestView < Monkeybars::View
      raw_mapping :to_view_method, nil
      attr_accessor :view_field
      
      def to_view_method(model, transfer)
        self.view_field = model.model_field * 10
      end
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    model.model_field = 4
    view.update(model, {})
    view.view_field.should == 40
    
    model.model_field = "a"
    view.update(model, {})
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
    t.update(m, {})
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
    v.update(m, {})
    v.view_property.should == "model property string"
  end
  
  it "ignores handlers when .ignoring is used"
end

describe "write_state method" do
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
    view.write_state(model, {})
    model.model_field.should == 7
    
    view.view_field = "string assigned to view property"
    view.write_state(model, {})
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
    view.write_state(model, {})
    model.model_field.should == 7
    
    view.view_field = "string assigned to view property"
    view.write_state(model, {})
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
    view.write_state(model, {})
    model.model_field.sub_field .should == 42
    
    view.view_field.sub_field = "string assigned to a nested property"
    view.write_state(model, {})
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
    view.write_state(model, {})
    model.model_field.should == 70
    
    view.view_field = "ha"
    view.write_state(model, {})
    model.model_field.should == "hahahahahahahahahaha"
  end
  
  it "invokes raw_mapping 'to_model' method when specified" do
    class TestView < Monkeybars::View
      raw_mapping nil, :method1
      attr_accessor :view_field
      
      def method1(model, transfer)
        model.model_field = "here you go: #{view_field}"
      end
    end
    
    class Model
      attr_accessor :model_field
    end
    
    view = TestView.new
    model = Model.new
    
    view.view_field = 99
    view.write_state(model, {})
    model.model_field.should == "here you go: 99"
    
    view.view_field = "text!"
    view.write_state(model, {})
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
    
    view.write_state(model, {})
    model.model_property.should == "some amazingly awesome view data"
  end
  
  it "ignores handlers when .ignoring is used"
end
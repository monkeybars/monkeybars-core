require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'monkeybars/view'
require 'spec/unit/test_files.jar'

require 'monkeybars/view_mapping'

TEST_DATA = "bazz"

describe Monkeybars::Mapping, "instantiation" do
  it "only accepts :view, :model, :tranfer, :using , :translate_using and :ignoring as parameter keys" do
      lambda{Monkeybars::Mapping.new(:view => '', :model => '', :using => '', :ignoring => '')}.should_not raise_error(InvalidHashKeyError)
      lambda{Monkeybars::Mapping.new(:view => '', :transfer => '', :using => '', :ignoring => '')}.should_not raise_error(InvalidHashKeyError)
      lambda{Monkeybars::Mapping.new(:view => '', :transfer => '', :translate_using => '', :ignoring => '')}.should_not raise_error(InvalidHashKeyError)
      lambda{Monkeybars::Mapping.new(:foo => '', :bar => '', :baz => '')}.should raise_error(InvalidHashKeyError)  
    end
    
    it "raises an InvalidMappingError when no parameters are given" do
      lambda {Monkeybars::Mapping.new()}.should raise_error(Monkeybars::InvalidMappingError)
    end
    
    it "raises an InvalidMappingError when only one side of the mapping is given" do
      lambda {Monkeybars::Mapping.new(:view => "")}.should raise_error(Monkeybars::InvalidMappingError)
      lambda {Monkeybars::Mapping.new(:model => "")}.should raise_error(Monkeybars::InvalidMappingError)
      lambda {Monkeybars::Mapping.new(:transfer => "")}.should raise_error(Monkeybars::InvalidMappingError)
    end
    
    it "raises an InvalidMappingError when both a model and transfer parameters are given" do
      lambda {Monkeybars::Mapping.new(:model => '', :transfer => '')}.should raise_error(Monkeybars::InvalidMappingError)
    end
    
    it "raises an InvalidMappingError when both a :using and :translate_using parameters are given" do
      lambda {Monkeybars::Mapping.new(:view => '', :model => '', :using => '', :translate_using => '')}.should raise_error(Monkeybars::InvalidMappingError)
    end
    
    it "creates a PropertyMapping object when a view and model are given" do
      Monkeybars::Mapping.new(:view => "", :model => "").class.should == Monkeybars::PropertyMapping
    end
    
    it "creates a PropertyMapping object when a view and transfer are given" do
      Monkeybars::Mapping.new(:view => "", :transfer => "").class.should == Monkeybars::PropertyMapping
    end
    
    it "identifies a mapping as model when a model parameter is given" do
      Monkeybars::Mapping.new(:view => "", :model => "").model_mapping?.should == true
    end
    
    it "identifies a mapping as transfer when a transfer parameter is given" do
      Monkeybars::Mapping.new(:view => "", :transfer => "").transfer_mapping?.should == true
    end
    
    it "sets the mapping direction to DIRECTION_BOTH when only properties are given" do
      Monkeybars::Mapping.new(:view => "", :model => "").send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_BOTH
      Monkeybars::Mapping.new(:view => "", :transfer => "").send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_BOTH
    end
    
    it "creates a MethodMapping object when one or two methods are provided" do
      Monkeybars::Mapping.new(:view => "", :transfer => "", :using => "").class.should == Monkeybars::MethodMapping
      Monkeybars::Mapping.new(:view => "", :transfer => "", :using => ["",""]).class.should == Monkeybars::MethodMapping
    end
    
    it "creates a MethodMapping object when :translate_using is provided" do
      Monkeybars::Mapping.new(:view => "", :transfer => "", :translate_using => {}).class.should == Monkeybars::MethodMapping
    end
    
    it "sets the mapping direction to DIRECTION_TO_VIEW when the first (or only one) method is provided" do
      Monkeybars::Mapping.new(:view => "", :transfer => "", :using => "").send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_TO_VIEW
      Monkeybars::Mapping.new(:view => "", :transfer => "", :using => ["", nil]).send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_TO_VIEW
      Monkeybars::Mapping.new(:using => "").send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_TO_VIEW
      Monkeybars::Mapping.new(:using => ["", nil]).send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_TO_VIEW
    end
    
    it "sets the mapping direction to DIRECTION_FROM_VIEW when the second method is provided" do
      Monkeybars::Mapping.new(:view => "", :transfer => "", :using => [nil, ""]).send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_FROM_VIEW
      Monkeybars::Mapping.new(:using => [nil, ""]).send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_FROM_VIEW
    end
    
    it "sets the mapping direction to DIRECTION_BOTH when two methods are provided" do
      Monkeybars::Mapping.new(:view => "", :transfer => "", :using => ["", ""]).send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_BOTH
      Monkeybars::Mapping.new(:using => ["", ""]).send(:instance_variable_get, "@direction").should == Monkeybars::Mapping::DIRECTION_BOTH
    end
    
    it "creates a RawMapping object when only one or two methods are provided" do
      Monkeybars::Mapping.new(:using => "").class.should == Monkeybars::RawMapping
      Monkeybars::Mapping.new(:using => [nil, ""]).class.should == Monkeybars::RawMapping
      Monkeybars::Mapping.new(:using => ["", ""]).class.should == Monkeybars::RawMapping  
    end
end

describe "Monkeybars::Mapping's transfer of data to the view" do
  it "uses the right hand value (value) on the translation to the view property" do
    class MockData; attr_accessor :foo, :bar ;end
    view = MockData.new
    model = MockData.new
    model.bar = :model_data
    
    mapping = Monkeybars::Mapping.new(:view => "foo", :model => "bar", :translate_using => {:model_data => "view_data"})
    mapping.to_view view, model, nil
    view.foo.should == "view_data"
  end
  
  it "transfers mapped model properties to the related view properties" do
    class MockData; attr_accessor :foo, :bar ;end
    view = MockData.new
    model = MockData.new
    model.bar = TEST_DATA
    
    mapping = Monkeybars::Mapping.new(:view => "foo", :model => "bar")
    mapping.to_view view, model, nil
    view.foo.should == TEST_DATA
  end
  
  it "transfers mapped transfer hash properties to the related view properties" do
    class MockData; attr_accessor :view_property ;end
    transfer = {"foo" => TEST_DATA, :bar => TEST_DATA}
     
    view = MockData.new
    mapping = Monkeybars::Mapping.new(:view => "view_property", :transfer => :bar)
    mapping.to_view view, nil, transfer
    view.view_property.should == TEST_DATA
    
    view = MockData.new
    mapping = Monkeybars::Mapping.new(:view => "view_property", :transfer => "foo")
    mapping.to_view view, nil, transfer
    view.view_property.should == TEST_DATA
  end
  
  it "transfers mapped model properties to the related view properties via a declared method" do
    class MockData
      attr_accessor :bar
      def in_method(foo)
        foo + 1
      end
    end
    model = Struct.new(:foo).new(5)
    view = MockData.new
    
    Monkeybars::Mapping.new(:view => "bar", :model => "foo", :using => :in_method).to_view(view, model, nil)
    view.bar.should == 6
  end
  
  it "transfers mapped transfer hash properties to the related view properties via a declared method" do
    class MockData
      attr_accessor :bar
      def in_method(foo)
	foo + 1
      end
    end
    transfer = {:foo => 5}
    view = MockData.new
    
    Monkeybars::Mapping.new(:view => "bar", :transfer => :foo, :using => :in_method).to_view(view, nil, transfer)
    view.bar.should == 6
  end
  
  it "invokes method declared by raw mapping" do
    class MockData; end
    view = MockData.new
    view.should_receive(:raw_in).twice
  
    Monkeybars::Mapping.new(:using => [:raw_in, nil]).to_view view, :model, :transfer
    Monkeybars::Mapping.new(:using => :raw_in).to_view view, :model, :transfer
  end
  
  it "triggers disabling of declared listeners" do
    model = Struct.new(:bar).new(:bar => "foo")
    view = mock("View")
 
    view.should_receive(:get_field_value).with("test_label").and_return(view)
    view.should_receive(:disable_handlers).twice #this would get called on the component, but we return view in the above call
    
    Monkeybars::Mapping.new(:view => 'test_label.text', :model => 'bar', :ignoring => ['anything', 'everything']).to_view(view, model, {})
  end
  
  it "maps :default methods as property mappings"
end

describe "Monkeybars::Mapping's transfer of data from the view" do
  it "uses the left hand value (key) on the translation to the view property" do
    class MockData; attr_accessor :foo, :bar ;end
    view = MockData.new
    model = MockData.new
    view.foo = "view_data"
    
    mapping = Monkeybars::Mapping.new(:view => "foo", :model => "bar", :translate_using => {:model_data => "view_data"})
    mapping.from_view(view, model, nil)
    model.bar.should == :model_data
  end
  
  it "transfers mapped model properties from the related view properties" do
    class MockData; attr_accessor :foo, :bar ;end
    view = MockData.new
    model = MockData.new
    view.foo = TEST_DATA
    
    mapping = Monkeybars::Mapping.new(:view => "foo", :model => "bar")
    mapping.from_view(view, model, nil)
    model.bar.should == TEST_DATA
  end
  
  it "transfers mapped transfer hash properties from the related view properties" do
    class MockData; attr_accessor :view_property ;end
    view = MockData.new
    view.view_property = TEST_DATA
  
    transfer = {}
    mapping = Monkeybars::Mapping.new(:view => "view_property", :transfer => :bar)
    mapping.from_view view, nil, transfer
    transfer[:bar].should == TEST_DATA
    
    transfer = {}
    mapping = Monkeybars::Mapping.new(:view => "view_property", :transfer => "foo")
    mapping.from_view view, nil, transfer
    transfer["foo"].should == TEST_DATA
  end
  
  it "transfers mapped model properties from the related view properties via a declared method" do
    class MockData
      attr_accessor :bar
      def out_method(model)
  @bar + 1
      end
    end
    model = Struct.new(:foo).new
    view = MockData.new
    view.bar = 5
    
    
    Monkeybars::Mapping.new(:view => "bar", :model => "foo", :using => [nil, :out_method]).from_view(view, model, nil)
    model.foo.should == 6
  end
  
  it "transfers mapped transfer hash properties from the related view properties via a declared method" do
    class MockData
      attr_accessor :bar
      def out_method(model)
  @bar + 1
      end
    end
    view = MockData.new
    
    transfer = {}
    view.bar = 5
    Monkeybars::Mapping.new(:view => "bar", :transfer => "foo", :using => [nil, :out_method]).from_view(view, nil, transfer)
    transfer["foo"].should == 6
    
    transfer = {}
    view.bar = 5
    Monkeybars::Mapping.new(:view => "bar", :transfer => :foo, :using => [nil, :out_method]).from_view(view, nil, transfer)
    transfer[:foo].should == 6
  end
  
  it "invokes method declared by raw mapping" do
    class MockData; end
    view = MockData.new
    view.should_receive(:raw_out)

    Monkeybars::Mapping.new(:using => [nil, :raw_out]).from_view view, :model, :transfer
  end
  
  it "maps :default methods as property mappings"
end

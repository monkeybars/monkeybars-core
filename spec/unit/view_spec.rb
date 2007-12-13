$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'java'
require 'monkeybars/view'
require 'spec/unit/test_files.jar'

class TestingView < Monkeybars::View
  set_java_class 'org.monkeybars.TestView'  
end

describe "view's get_field_value method" do
  it "should return a reference to the java field's value" do
    view = TestingView.new
    view.send(:get_field_value, :test_label).text.should == "A Test Label"
    view.send(:get_field_value, :test_label).text = "New Label"
    view.send(:get_field_value, :test_label).text.should == "New Label"
    view.instance_variable_get("@main_view_component").dispose #Make swing threads go away so test can exit
  end
  
  it "can return a reference to a primitive field" do
    view = TestingView.new
    view.send(:get_field_value, :primitive_variable).should == 20
    view.send(:get_field_value, :object_variable).should == 30
    view.instance_variable_get("@main_view_component").dispose
  end
  
  it "returns same reference on subsequent calls" do
    view = TestingView.new
    label = view.send(:get_field_value, :test_label)
    label2 = view.send(:get_field_value, :test_label)
    label.should equal(label2)
    view.instance_variable_get("@main_view_component").dispose
  end
end

describe "view's get_field method" do
  it "uses cached reference to a field if it is available" do
    view = TestingView.new
    view.instance_variable_get(:@__field_references)[:test_label] = "test data that replaces actual field"
    view.send(:get_field, :test_label).should == "test data that replaces actual field"
    view.instance_variable_get("@main_view_component").dispose
  end
end

describe "view's validate_mapping method" do
  it "identifies mappings as in-only, out-only, or bi-directional"
  it "detects mis-named methods declared in a mapping"
end
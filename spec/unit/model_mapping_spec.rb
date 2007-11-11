$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'java'
require 'monkeybars/view'

describe "model mapping instance" do
  
  before(:each) do
    @mapping = Monkeybars::View::ModelMapping.new
  end
  
  it "detects when no properties are present" do
    @mapping.send(:at_least_one_property_present?).should == false
  end
  
  it "detects when view property is present" do
    @mapping.view_property = true
    @mapping.send(:at_least_one_property_present?).should == true
  end

  it "detects when model property is present" do
    @mapping.model_property = true
    @mapping.send(:at_least_one_property_present?).should == true
  end
  
  it "detects when both properties are present" do
    @mapping.both_properties_present?.should == false
    @mapping.model_property = true
    @mapping.both_properties_present?.should == false
    @mapping.view_property = true
    @mapping.both_properties_present?.should == true
  end
  
  it "detects when no methods are present" do
    @mapping.send(:at_least_one_method_present?).should == false
  end
  
  it "detects when 'in' method is present" do
    @mapping.in_method_present?.should == false
    @mapping.in_method = true
    @mapping.in_method_present?.should == true
  end
  
  it "detects when 'out' method is present" do
    @mapping.out_method_present?.should == false
    @mapping.out_method = true
    @mapping.out_method_present?.should == true
  end
  
  it "detects when a method is present (in method)" do
    @mapping.send(:at_least_one_method_present?).should == false
    @mapping.in_method = true
    @mapping.send(:at_least_one_method_present?).should == true
  end

  it "detects when a method is present (out method)" do
    @mapping.send(:at_least_one_method_present?).should == false
    @mapping.out_method = true
    @mapping.send(:at_least_one_method_present?).should == true
  end
  
  it "detects when both methods are present" do
    @mapping.both_methods_present?.should == false
    @mapping.in_method = true
    @mapping.both_methods_present?.should == false
    @mapping.out_method = true
    @mapping.both_methods_present?.should == true
  end
  
  it "detects when only properties are present" do
    @mapping.properties_only?.should == false
    @mapping.view_property = true
    @mapping.properties_only?.should == true
    @mapping.in_method = true
    @mapping.properties_only?.should == false
  end
  
  it "detects when only methods are present" do
    @mapping.methods_only?.should == false
    @mapping.in_method = true
    @mapping.methods_only?.should == true
    @mapping.view_property = true
    @mapping.properties_only?.should == false
  end
  
  it "detects when both properties and methods are present" do
    @mapping.both_properties_and_methods?.should == false
    @mapping.view_property = true
    @mapping.both_properties_and_methods?.should == false
    @mapping.in_method = true
    @mapping.both_properties_and_methods?.should == false
    @mapping.model_property = true
    @mapping.both_properties_and_methods?.should == true
  end
end
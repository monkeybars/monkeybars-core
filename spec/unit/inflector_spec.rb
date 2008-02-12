$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'monkeybars/inflector'

describe Monkeybars::Inflector do
  it "should add in constantize, camelize and underscore methods to String and Symbol" do
    String.instance_methods.member?("constantize").should be_true
    String.instance_methods.member?("camelize").should be_true
    String.instance_methods.member?("underscore").should be_true
    
    Symbol.instance_methods.member?("constantize").should be_true
    Symbol.instance_methods.member?("camelize").should be_true
    Symbol.instance_methods.member?("underscore").should be_true
  end
end

describe Monkeybars::Inflector, "#constantize" do
  it "takes a string or symbol and returns the constant of the same name" do
    class SomeConstant; end
    
    "SomeConstant".constantize.should == SomeConstant
  end
end

describe Monkeybars::Inflector, "#underscore" do
  it "converts a name string to the underscored version of that name" do
    "UpperCaseName".underscore.should == "upper_case_name"
    "upperCaseName".underscore.should == "upper_case_name"
    "upper_case_name".underscore.should == "upper_case_name"
  end
end

describe Monkeybars::Inflector, "#camelize" do
  it "converts a name string to the 'camel case' version of that name with a lower case first character" do
    "lower_case_name".camelize.should == "LowerCaseName"
    "lowerCaseName".camelize.should == "LowerCaseName"
    "LowerCaseName".camelize.should == "LowerCaseName"
  end
  
  it "uses an upper case first character if passed a true parameter" do
    "lower_case_name".camelize(false).should == "lowerCaseName"
    "lowerCaseName".camelize(false).should == "lowerCaseName"
    "LowerCaseName".camelize(false).should == "LowerCaseName" #doesn't modify the first character
  end
end

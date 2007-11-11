$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'java'
require 'monkeybars/controller'

describe "MonkeybarsWindowAdapter" do
  def handler_method; end
  
  it "requires argument for the constructor" do
    lambda {Monkeybars::MonkeybarsWindowAdapter.new()}.should raise_error(ArgumentError)
  end
  
  it "only allows existing methods to be defined" do
    lambda {Monkeybars::MonkeybarsWindowAdapter.new(:someMadeUpMethod => nil)}.should raise_error(ArgumentError)
    lambda {Monkeybars::MonkeybarsWindowAdapter.new(:windowClosing => method(:handler_method))}.should_not raise_error(ArgumentError)
  end
  
  it "requires a proc must be provided along with a valid method name" do
    lambda {Monkeybars::MonkeybarsWindowAdapter.new(:windowClosing => nil)}.should raise_error(ArgumentError)
    lambda {Monkeybars::MonkeybarsWindowAdapter.new(:windowClosing => method(:handler_method))}.should_not raise_error(ArgumentError)
  end
  
end
$:.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require 'java'
require 'monkeybars/controller'

describe "controller instantiation" do
  it "should only create one instance by default" do
    class TestController < Monkeybars::Controller; end
    
    t = TestController.instance
    t2 = TestController.instance
    t.should equal(t2)
  end
  
  it "should allow the creation of multiple instances when 'allow :multiple' is declared"
end


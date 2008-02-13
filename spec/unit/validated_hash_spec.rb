$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

describe "ValidatedHash mixin" do
  it "adds three methods named validate_only, validate_all and validate_none to the Hash class" do
    unless Object.const_defined? :ValidatedHash
      Hash.new.methods.member?('validate_only').should == false
      Hash.new.methods.member?('validate_all').should == false
      Hash.new.methods.member?('validate_none').should == false

      require 'monkeybars/validated_hash'
    end
    
    Hash.new.methods.member?('validate_only').should == true
    Hash.new.methods.member?('validate_all').should == true
    Hash.new.methods.member?('validate_none').should == true
  end
  
  it "validate_only method raises an error if any keys not passed in exist in the hash" do
    lambda { {:a => "a"}.validate_only(:a, :b) }.should_not raise_error(InvalidHashKeyError)
    lambda { {:a => "a", :b => "b"}.validate_only(:a, :b) }.should_not raise_error(InvalidHashKeyError)
    lambda { {:a => "a", :b => "b", :c => "c"}.validate_only(:a, :b) }.should raise_error(InvalidHashKeyError)
    lambda { {:a => "a", :c => "c"}.validate_only(:a, :b) }.should raise_error(InvalidHashKeyError)
    lambda { {:b => "b", :c => "c"}.validate_only(:a, :b) }.should raise_error(InvalidHashKeyError)
  end
  
  it "validate_all method raises an error if any keys passed in do not exist in the hash" do
    lambda { {:a => "a", :b => "b", :c => "c"}.validate_all(:a, :b, :c)}.should_not raise_error(InvalidHashKeyError)
    lambda { {:a => "a", :b => "b", :c => "c", :d => "d"}.validate_all(:a, :b, :c)}.should_not raise_error(InvalidHashKeyError)
    
    lambda { {:a => "a", :b => "b"}.validate_all(:a, :b, :c)}.should raise_error(InvalidHashKeyError)
    lambda { {:a => "a", :c => "c"}.validate_all(:a, :b, :c)}.should raise_error(InvalidHashKeyError)
    lambda { {:b => "b", :c => "c"}.validate_all(:a, :b, :c)}.should raise_error(InvalidHashKeyError)
    
    lambda { {:a => "a", :b => "b", :d => "d"}.validate_all(:a, :b, :c)}.should raise_error(InvalidHashKeyError)
  end
  
  it "validate_none method raises an error if any keys passed in exist in the hash" do
    lambda { {:d => "d", :e => "e", :f => "f"}.validate_none(:a, :b, :c)}.should_not raise_error(InvalidHashKeyError)
    lambda { {:d => "d", :e => "e", :f => "f", :a => "a"}.validate_none(:a, :b, :c)}.should raise_error(InvalidHashKeyError)
    lambda { {:d => "d", :e => "e", :f => "f", :b => "b"}.validate_none(:a, :b, :c)}.should raise_error(InvalidHashKeyError)
    lambda { {:d => "d", :e => "e", :f => "f", :c => "c"}.validate_none(:a, :b, :c)}.should raise_error(InvalidHashKeyError)
    lambda { {:a => "a", :b => "b", :c => "c"}.validate_none(:a, :b, :c)}.should raise_error(InvalidHashKeyError)
  end
end
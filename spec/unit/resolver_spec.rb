require 'skeleton/src/resolver'

describe Object, "#get_expanded_path" do
  it "resolves both Unix and Windows style paths" do
    get_expanded_path("foo/bar/baz").index("foo/bar/baz").should > 0
    get_expanded_path("foo2\\bar2\\baz2").index("foo2/bar2/baz2").should > 0
  end
  
  it "removes file: from path if the path does not resolve to inside a jar" do
    get_expanded_path("foo/bar/baz").index("file:").should be_nil
  end
end



require 'monkeybars/view_nesting'

describe Monkeybars::Nesting do
  it 'creates PropertyNesting with :sub_view and :view' do
    Monkeybars::Nesting.new(:view => "foo", :sub_view => "bar").should be_an_instance_of(Monkeybars::PropertyNesting)
  end
  it 'creates MethodNesting with :sub_view and :using' do
    Monkeybars::Nesting.new(:sub_view => "foo", :using => ["add_foo", "remove_foo"]).should be_an_instance_of(Monkeybars::MethodNesting)
  end
end

describe Monkeybars::MethodNesting do
  it 'calls the first/only :using method on add' do
    nesting = Monkeybars::Nesting.new(:sub_view => "foo", :using => [:add_foo, :remove_foo])
    view = mock("view")
    
    view.should_receive :add_foo
    
    nesting.add(view, nil, nil, nil, nil)
  end
  
  it 'calls the second :using method on remove' do
    nesting = Monkeybars::Nesting.new(:sub_view => "foo", :using => [:add_foo, :remove_foo])
    view = mock("view")
    
    view.should_receive :remove_foo
    
    nesting.remove(view, nil, nil, nil, nil)
  end
end

describe Monkeybars::PropertyNesting do
  it 'calls add on the :view container component on add' do
    nesting = Monkeybars::Nesting.new(:view => "foo", :sub_view => "bar")
    view = mock("view")
    view_component = mock("view_component")
    view.stub!(:foo).and_return view_component
    
    nested_component = mock("nested_component")
    view_component.should_receive(:add).with(nested_component)
    
    nesting.add(view, nil, nested_component, nil, nil)
  end
  
  it 'calls remove on the :view container component on remove' do
    nesting = Monkeybars::Nesting.new(:view => "foo", :sub_view => "bar")
    view = mock("view")
    view_component = mock("view_component")
    view.stub!(:foo).and_return view_component
    
    nested_component = mock("nested_component")
    view_component.should_receive(:remove).with(nested_component)
    
    nesting.remove(view, nil, nested_component, nil, nil)
  end
end
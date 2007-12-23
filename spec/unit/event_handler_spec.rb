require 'monkeybars/event_handler'

describe "Monkeybars::Handler module" do
  before(:each) do
    
  end

  it "contains the hash EVENT_NAMES, its keys are every action for every Swing/AWT event type, the value is the associated type" do
    # It's impractical to test *every* action so we pick some random methods from a variety of listeners
    Monkeybars::Handlers::EVENT_NAMES["action_performed"].should == "Action"
    Monkeybars::Handlers::EVENT_NAMES["item_state_changed"].should == "Item"
    Monkeybars::Handlers::EVENT_NAMES["mouse_entered"].should == "Mouse"
    Monkeybars::Handlers::EVENT_NAMES["mouse_moved"].should == "MouseMotion"
    Monkeybars::Handlers::EVENT_NAMES["internal_frame_closing"].should == "InternalFrame"
    Monkeybars::Handlers::EVENT_NAMES["menu_selected"].should == "Menu"
    Monkeybars::Handlers::EVENT_NAMES["value_changed"].should == "ListSelection"
  end
end
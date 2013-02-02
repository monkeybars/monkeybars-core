require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'monkeybars'

describe "disable_handlers method" do
  it "should be available on java.awt.Component and subclasses" do
    java.awt.Component.instance_methods.member?(:disable_handlers).should be_true
    java.awt.Container.instance_methods.member?(:disable_handlers).should be_true
    java.awt.Button.instance_methods.member?(:disable_handlers).should be_true
    javax.swing.JComponent.instance_methods.member?(:disable_handlers).should be_true
    javax.swing.JComboBox.instance_methods.member?(:disable_handlers).should be_true
  end
  
  it "should remove all handlers of a given type before yielding to the given block and then add the handlers back" do
    class ActionHandler
      include java.awt.event.ActionListener
      
      def method_missing(method, *args, &blk); end
    end
    
    test_component = java.awt.Button.new
    test_component.add_action_listener ActionHandler.new
    test_component.add_action_listener ActionHandler.new
    test_component.get_listeners(java.awt.event.ActionListener.java_class).size.should == 2
    
    test_component.disable_handlers(:action) do
      test_component.get_listeners(java.awt.event.ActionListener.java_class).size.should == 0
    end
    
    test_component.get_listeners(java.awt.event.ActionListener.java_class).size.should == 2
  end
  
  it "can remove handlers inside a handler for that action type" do
    class DisablingHandler
      include java.awt.event.ActionListener
      
      def initialize(component, event)
        @component = component
        @handler_called = false
      end
      
      def actionPerformed(event)
        @handler_called.should == false
        @handler_called = true
        
        @component.disable_handlers(:action) do
          @component.dispatch_event(event)
        end
      end
    end
    
    test_component = java.awt.Button.new
    event = java.awt.event.ActionEvent.new(test_component, 1001, "")
    
    test_component.add_action_listener DisablingHandler.new(test_component, event)
    
    test_component.dispatch_event(event)
  end
  
  it "should accept one or more handlers to be disabled" do
    class ActionHandler
      include java.awt.event.ActionListener
      
      def method_missing(method, *args, &blk); end
    end
    
    class MouseHandler
      include java.awt.event.MouseListener
      
      def method_missing(method, *args, &blk); end
    end
    
    test_component = java.awt.Button.new
    test_component.add_action_listener ActionHandler.new
    test_component.add_action_listener ActionHandler.new
    test_component.add_mouse_listener MouseHandler.new
    test_component.add_mouse_listener MouseHandler.new
    test_component.get_listeners(java.awt.event.ActionListener.java_class).size.should == 2
    test_component.get_listeners(java.awt.event.MouseListener.java_class).size.should == 2
    
    test_component.disable_handlers(:action, :mouse) do
      test_component.get_listeners(java.awt.event.ActionListener.java_class).size.should == 0
      test_component.get_listeners(java.awt.event.MouseListener.java_class).size.should == 0
    end
    
    test_component.get_listeners(java.awt.event.ActionListener.java_class).size.should == 2
    test_component.get_listeners(java.awt.event.MouseListener.java_class).size.should == 2
  end
end
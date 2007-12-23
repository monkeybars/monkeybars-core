require 'monkeybars/inflector'

module Monkeybars
    # This class is primarily used internally for setting up a handler for window 
  # close events although any of the WindowAdapter methods can be set.  To instantiate
  # a new MonkeybarsWindowAdapter, pass in a hash of method name symbols and method 
  # objects.  The method names must be the various methods from the 
  # java.awt.event.WindowListener interface.
  #
  # For example:
  #
  #   def handle_window_closing(event)
  #     puts "the window is closing"
  #   end
  #   
  #   handler = MonkeybarsWindowAdapter.new(:windowClosing => method(handle_window_closing))
  class MonkeybarsWindowAdapter #:nodoc:
    def initialize(methods)
      super()
      raise ArgumentError if methods.empty?
      methods.each { |method, proc| raise ArgumentError.new("Only window and internalFrame events can be used to create a MonkeybarsWindowAdapter") unless (/^(window|internalFrame)/ =~ method.to_s) and (proc.respond_to? :to_proc) }
      @methods = methods
    end

    def method_missing(method, *args, &blk)
      if /^(window|internalFrame)/ =~ method.to_s
        @methods[method].call(*args) if @methods[method]
      else
        super
      end
    end
  end  
  
  
  # This module is used internally by the various XYZHandler classes as the
  # recipent of events. It dispatches the event handling to the controller's
  # handle_event method.
  module BaseHandler
    def method_missing(method, *args, &block)
      @controller.handle_event(method.underscore, args[0])
    end
  end

  module Handlers
    AWT_TYPES = ["Action","Adjustment","AWTEvent","Component","Container","Focus",
             "HierarchyBounds","Hierarchy","InputMethod","Item","Key","Mouse",
             "MouseMotion","MouseWheel","Text", "WindowFocus","Window","WindowState"]       
    SWING_TYPES = ["Ancestor", "Caret", "CellEditor", "Change", "Document", 
                   "Hyperlink", "InternalFrame", "ListData", "ListSelection", 
                   "MenuDragMouse", "MenuKey", "Menu", "MouseInput", "PopupMenu", 
                   "TableColumnModel", "TableModel", "TreeExpansion", "TreeModel", 
                   "TreeSelection", "TreeWillExpand", "UndoableEdit"]
    EVENT_NAMES = {}
  end
end

{"java.awt.event" => Monkeybars::Handlers::AWT_TYPES, "javax.swing.event" => Monkeybars::Handlers::SWING_TYPES}.each do |java_package, types|
  types.each do |type|
    eval <<-ENDL
      module Monkeybars
        class #{type}Handler
          def initialize(controller)
            @controller = controller
          end

          include Monkeybars::BaseHandler
          include #{java_package}.#{type}Listener
        end
      end
    ENDL
    
    unless ["MouseInput", "HierarchyBounds", "TreeSelection"].member? type
      interface = eval "#{java_package}.#{type}Listener"
      interface.java_class.java_instance_methods.each do |method|
        puts "duplicate method name: #{method.name.underscore} for type #{type}, has an existing type of #{Monkeybars::Handlers::EVENT_NAMES[method.name.underscore]}" if Monkeybars::Handlers::EVENT_NAMES[method.name.underscore]
        Monkeybars::Handlers::EVENT_NAMES[method.name.underscore] = type
      end
    end
    
  end
end
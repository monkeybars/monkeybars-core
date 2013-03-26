require 'monkeybars/inflector'

java_import 'javax.swing.SwingUtilities'

module Monkeybars
  # This class is primarily used internally for setting up a handler for window 
  # close events although any of the WindowAdapter methods can be set.  To instantiate
  # a new MonkeybarsWindowAdapter, pass in a hash of method name symbols and method 
  # objects.  The method names must be the various methods from the 
  # java.awt.event.WindowListener interface.
  #
  # For example:
  #
  #   def handle_window_closing event
  #     puts "the window is closing"
  #   end
  #   
  #   handler = MonkeybarsWindowAdapter.new(:windowClosing => method(handle_window_closing))
  class MonkeybarsWindowAdapter #:nodoc:
    def initialize methods
      super()
      raise ArgumentError if methods.empty?
      methods.each { |method, proc| raise ArgumentError.new("Only window and internalFrame events can be used to create a MonkeybarsWindowAdapter") unless (/^(window|internalFrame)/ =~ method.to_s) and (proc.respond_to? :to_proc) }
      @methods = methods
    end

    def method_missing method, *args, &blk
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
    def method_missing method, *args, &block
      @callback.handle_event @component_name, method.underscore, args[0]
      @callback.update_view if @auto_invoke_update_view
    end
  end

  module Handlers
    # TODO: add bean types like vetoable change, property change, etc.
    BEAN_TYPES = ["PropertyChange"]
    AWT_TYPES = ["Action","Adjustment","AWTEvent","Component","Container","Focus",
             "HierarchyBounds","Hierarchy","InputMethod","Item","Key","Mouse",
             "MouseMotion","MouseWheel","Text", "WindowFocus","Window","WindowState"]       
    SWING_TYPES = ["Ancestor", "Caret", "CellEditor", "Change", "Document", 
                   "Hyperlink", "InternalFrame", "ListData", "ListSelection", 
                   "MenuDragMouse", "MenuKey", "Menu", "MouseInput", "PopupMenu", 
                   "TableColumnModel", "TableModel", "TreeExpansion", "TreeModel", 
                   "TreeSelection", "TreeWillExpand", "UndoableEdit"]
    ALL_EVENT_NAMES = []
    EVENT_NAMES_BY_TYPE = Hash.new{|h,k| h[k] = []}
  end
end

{"java.awt.event" => Monkeybars::Handlers::AWT_TYPES, "javax.swing.event" => Monkeybars::Handlers::SWING_TYPES, "java.beans" => Monkeybars::Handlers::BEAN_TYPES}.each do |java_package, types|
  types.each do |type|
    eval <<-ENDL
      module Monkeybars
        class #{type}Handler
          def initialize callback, component_name, auto_invoke_update_view = false
            @callback = callback
            @component_name = component_name
            @auto_invoke_update_view = auto_invoke_update_view
          end

          def type
            "#{type}"
          end

          include Monkeybars::BaseHandler
          include #{java_package}.#{type}Listener
        end
      end
    ENDL
    
    interface = eval "#{java_package}.#{type}Listener"
    interface.java_class.java_instance_methods.each do |method|
      Monkeybars::Handlers::ALL_EVENT_NAMES << method.name.underscore
      Monkeybars::Handlers::EVENT_NAMES_BY_TYPE[type] << method.name.underscore
    end
    Monkeybars::Handlers::ALL_EVENT_NAMES.uniq!
  end
end

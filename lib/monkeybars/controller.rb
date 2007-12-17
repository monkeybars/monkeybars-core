require 'thread'

require "monkeybars/inflector"
require "monkeybars/view"

module Monkeybars
  # Controllers are the traffic cops of your application.  They decide how to react to
  # events, they coordinate interaction with other controllers and they define some of
  # the overall characteristics of a view such as which events it will generate and how
  # it should respond to things like the close button being pressed.
  # For a general introduction to the idea of MVC and the role of a controller, 
  # please see: http://en.wikipedia.org/wiki/Model-view-controller
  #
  # The controller defines the model and view classes it is associated with.  Most
  # controllers will declare a view and a model that will be instantiated along with
  # the controller and whose life cycle is managed by the controller.  It is not required
  # to declare a view or model but a controller is of questionable usefulness without it.
  #
  # The controller is where you define any events you are interested in handling
  # (see add_listener) as well as one special event, the pressing of the "close" button
  # of the window (see close_action).  Handlers can
  #
  # Example of a controller, this assumes the existance of a Ruby class named MyModel that
  # has an attribute named user_name that is mapped to a field on a subclass of 
  # Monkeybars::View named MyView that has a button named "okButton" and a text field called 
  # userNameTextField:
  #
  #   require 'monkeybars'
  #   
  #   class MyController < Monkeybars::Controller
  #     set_view :MyView
  #     set_model :MyModel
  # 
  #     add_listener :type => :mouse, :components => ["okButton"]
  #     close_action :exit
  # 
  #     def ok_button_mouse_released(view_state, event)
  #       puts "The user's name is: #{view_state.user_name}"
  #     end
  #   end
  #
  # It is important that you do not implement your own initialize and update methods, this
  # will interfere with the operation of the Controller class (or if you do be sure to call
  # super as the first line).
  #
  class Controller
    METHOD_NOT_FOUND = :method_not_found
    @@instance_list = Hash.new {|hash, key| hash[key] = []}
    @@instance_lock = Mutex.new
    
    # Controllers cannot be instantiated via a call to new, instead use instance
    # to retrieve the instance of the view.  Currently only one instance of a
    # controller is created but in the near future a configurable limit will be
    # available so that you can create n instance of a controller.
    def self.instance
      @@instance_lock.synchronize do
        controller = @@instance_list[self]
        unless controller.empty?
          controller.size == 1 ? controller[0] : controller
        else
          __new__
        end
      end
    end
    
    # Declares the view class (as a symbol) to use when instantiating the controller.
    # 
    #   set_view :MyView
    #
    # The file my_view.rb will be auto-required before attempting to instantiate
    # the MyView class.
    #
    def self.set_view(view)
      require view.underscore unless view.constantize
      self.view_class = view.constantize
    end

    # See set_view.  The declared model class is also auto-required prior to the
    # class being instantiated.
    def self.set_model(model)
      require model.underscore unless model.constantize
      self.model_class = model.constantize
    end

    # Declares which components you want events to be generated for.  add_listener
    # takes a hash of the form :type => type, :components => [components for events]
    # All AWT and Swing listener types are supported.  See Monkeybars::Handlers for
    # the full list.
    #
    # The array of components should be strings or symbols with the exact naming of the 
    # component in the Java class declared in the view.  As an example, if you have a JFrame 
    # with a text area named infoTextField that you wanted to receive key events for, perhaps
    # to filter certain key input or to enable an auto-completion feature you could use:
    #
    #   add_listener :type => :key, :components => [:infoTextField]
    #
    # To handle the event you would then need to implement a method named
    # <component>_<event> which in this case would be info_text_field_key_pressed,
    # info_text_field_key_released or info_text_field_key_typed.
    #
    # If you want to add a listener to all the components on the view you can leave
    # off the :components => key.  This is equivalent to :components => ["global"].
    # NOTE: ANY COMPONENTS ADDED VIA THIS "GLOBAL" MECHANISM MUST HAVE THEIR NAME
    # PROPERTY SET OR METHOD SPECIFIC method_name_action_name STYLE HANDLERS WILL 
    # *NOT* WORK.
    # 
    # If you want to add a listener to the view itself (JFrame, JDialog, etc.)
    # then you can use :java_window as the component
    # 
    #   add_listener :type => :window, :components => [:java_window]
    #
    # If it is not possible to declare a method, or it is desirable to do so dynamically
    # (even from outside the class), you can use the define_handler method.
    def self.add_listener(details)
      self.send(:class_variable_get, :@@handlers).push(details)
      hide_protected_class_methods #workaround for JRuby bug #1283
    end
  
    # Declares a method to be called whenever the controller's update method is called.
    def self.update_method(method)
      raise "Argument must be a symbol" unless method.kind_of? Symbol
      raise "'Update' is a reserved method name" if :update == method
      self.send(:class_variable_set, :@@update_method_name, method)
    end
  
    # define_handler takes a component/event name and a block to be called when that
    # event is generated for that component.  This can be used in place of a method
    # declaration for that component/event pair.
    #
    # So, if you have declared:
    #
    #   add_listener :type => :mouse, :components => [:okButton]
    #
    # you could implement the handler using:
    #
    #   define_handler(:ok_button_mouse_released) do |view_state, event|
    #     # handle the event here
    #   end
    def self.define_handler(action, &block)
      event_handler_procs[action] = block
    end
    
    # Valid close actions are
    # * :nothing
    # * :close (default)
    # * :exit
    # * :method => symbol_of_method_to_invoke_on_close
    # * :dispose
    # * :hide
    #
    # - action :nothing - close action is ignored, this means you cannot
    #   close the window unless you provide another way to do this
    # - action :close - calls the controller's close method
    # - action :exit - closes the application when the window's close
    #   button is pressed    
    # - action :method => :my_close_method # sets a window listener to
    #   invoke :my_close_method when the windowClosing event is fired
    # - action :dispose - default action, calls Swing's dispose method which
    #   will release the resources for the window and its components, can be 
    #   brought back with a call to show
    # - action :hide - sets the visibility of the window to false
    def self.close_action(action)
      self.send(:class_variable_set, :@@close_action, action)
    end
    
    def self.inherited(subclass) #:nodoc:
      subclass.send(:class_variable_set, :@@handlers, Array.new)
    end
    

    # Returns a frozen hash of ControllerName => [instances] pairs. This is
    # useful if you need to iterate over all active controllers to call update
    # or to check for a status.
    #
    # # NOTE: Controllers that have close called on them will not show up on this
    # list, even if open is subsequently called. If you need a window to remain
    # in the list but not be updated when not visible you can do:
    #
    #   Monkeybars::Controller.active_controllers.values.flatten.select{|c| c.visible? }.each{|c| c.update }
    def self.active_controllers
      @@instance_list.clone.freeze     
    end
    
    private 
    @@event_handler_procs = {}
    def self.event_handler_procs
      @@event_handler_procs[self] ||= {}
    end
    
    def self.hide_protected_class_methods #JRuby bug #1283
      private_class_method :new
    end
    
    hide_protected_class_methods
    
    def self.__new__
      object = new
      @@instance_list[self] << object
      object
    end    
    
    def initialize
      @__view = create_new_view unless self.class.view_class.nil?
      @__model = create_new_model unless self.class.model_class.nil?
      @__event_callback_mappings = {}
      
      handlers = self.class.send(:class_variable_get, :@@handlers)

      unless @__view.nil?
        handlers.each do |handler|            
          add_handler_for handler[:type], handler[:components]
        end
      else
        unless handlers.empty?
          raise "A view must be declared in order to add event listeners"
        end
      end

      if self.class.class_variables.member?("@@update_method_name")
        begin
          self.class.send(:class_variable_set, :@@update_method, method(self.class.send(:class_variable_get, :@@update_method_name)))
        rescue NameError
          raise "Update method: '#{self.class.send(:class_variable_get, :@@update_method_name)}' was not found for class #{self.class}"
        end  
      end
      
      if self.class.class_variables.member?("@@close_action")
        action = self.class.send(:class_variable_get, :@@close_action)
      else
        action = :close
      end
        
      unless @__view.nil?
        case action.kind_of?(Hash) ? action.keys[0] : action
        when :nothing
          @__view.close_action(Monkeybars::View::CloseActions::DO_NOTHING)
        when :dispose
          @__view.close_action(Monkeybars::View::CloseActions::DISPOSE)
        when :exit
          @__view.close_action(Monkeybars::View::CloseActions::EXIT)
        when :hide
          @__view.close_action(Monkeybars::View::CloseActions::HIDE)
        when :close
          @__view.close_action(Monkeybars::View::CloseActions::METHOD, MonkeybarsWindowAdapter.new(:windowClosing => self.method(:built_in_close_method)))
        when :method
          begin
            close_handler = self.method(action[:method])
          rescue NameError
            raise "Close action method: '#{action[:method]}' was not found for class #{self.class}"
          end
          @__view.close_action(Monkeybars::View::CloseActions::METHOD, MonkeybarsWindowAdapter.new(:windowClosing => close_handler))
        else
          raise "Unkown close action: #{action.kind_of? Hash ? action.keys[0] : action}"
        end
      end

      @closed = true
    end

    public
    def update
      self.class.send(:class_variable_get, :@@update_method).call if self.class.class_variables.member?("@@update_method_name")
    end

    # Triggers updating of the view based on the mapping and the current contents
    # of model
    def update_view
      @__view.update_from_model(model)
    end
    
    # Returns true if the view is visible, false otherwise
    def visible?
      @__view.visible?
    end

    # Hides the view
    def hide
      @__view.hide
    end

    # Shows the view
    def show
      @__view.show         
    end
    
    # True if close has been called on the controller
    def closed?
      @closed
    end

    # Hides the view and unloads its resources
    def close
      @closed = true          
      @__view.unload
      unload
      @__view.dispose if @__view.respond_to? :dispose
      @@instance_lock.synchronize do
        @@instance_list[self.class].delete self
      end
    end

    # Calls load if the controller has not been opened previously, then calls update_view
    # and shows the view.
    def open(*args)
      if closed?
        load(*args) 
        @closed = false
      end
      
      update_view
      show
    end

    
    # Stub to be overriden in sub-class.  This is where you put the code you would
    # normally put in initialize, it will be called the first time open is called
    # on the controller.
    def load(*args); end

    # Stub to be overriden in sub-class.  This is called whenever the controller is closed.
    def unload; end

    # Specific handlers get precedence over general handlers, that is button_mouse_released
    # gets called before mouse_released. A component's name field must be defined in order
    # for the name_event_type style handlers to work.
    def handle_event(event_name, event) #:nodoc:
      return if event.nil?

      component_name = @__event_callback_mappings[event.source]
      method = "#{component_name}_#{event_name}".to_sym
     
      proc = get_method(method)
      unless METHOD_NOT_FOUND == proc
        proc.call(event)
      else
        method = event_name.to_sym
        proc = get_method(method)
        
        unless METHOD_NOT_FOUND == proc
          proc.call(event)
        end
      end
    end
    
    private
    @@model_class_for_child_controller = {}
    def self.model_class
      @@model_class_for_child_controller[self]
    end
    
    def self.model_class=(model)
      @@model_class_for_child_controller[self] = model
    end
    
    def model
      @__model
    end
    
    def create_new_model
      self.class.model_class.new
    end
    
    @@view_class_for_child_controller = {}
    def self.view_class
      @@view_class_for_child_controller[self]
    end
    
    def self.view_class=(view)
      @@view_class_for_child_controller[self] = view
    end
    
    # Returns the contents of the view as defined by the view's mappings.  For use
    # in event handlers.  In an event handler this method is thread safe as Swing
    # is single threaded and blocks any modification to the GUI while the handler
    # is being proccessed.
    def view_state
      model = create_new_model unless self.class.model_class.nil?
      @__view.write_state_to_model(model)
      model
    end
    
    def create_new_view
      self.class.view_class.new
    end
    
    def add_handler_for(handler_type, components)
      handler = "Monkeybars::#{handler_type.camelize}Handler".constantize.new(self)
      mappings = @__view.add_handler(handler_type, handler, components)
      @__event_callback_mappings.merge! mappings
    end
    
    def get_method(method)
      begin
        method(method)
      rescue NameError
        proc = self.class.event_handler_procs[method]
        if proc.nil?
          METHOD_NOT_FOUND
        else
          proc
        end
      end
    end
    
    def built_in_close_method(event)
      close
    end
  end
  
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
  end
end
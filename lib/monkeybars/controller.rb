require 'thread'

require "monkeybars/inflector"
require "monkeybars/view"
require "monkeybars/event_handler"
require "monkeybars/task_processor"
module Monkeybars
  # Controllers are the traffic cops of your application.  They decide how to react to
  # events, they coordinate interaction with other controllers and they define some of
  # the overall characteristics of a view such as which events it will generate and how
  # it should respond to things like the close button being pressed.
  # For a general introduction to the idea of MVC and the role of a controller, 
  # please see: http://en.wikipedia.org/wiki/Model-view-controller.  Monkeybars is not, 
  # strictly speaking, an MVC framework.  However the general idea of the seperations 
  # of concerns that most people think of when you say 'MVC' is applicable.
  #
  # The controller defines the model and view classes it is associated with.  Most
  # controllers will declare a view and a model that will be instantiated along with
  # the controller and whose life cycle is managed by the controller.  It is not required
  # to declare a view or model but a controller is of questionable usefulness without it.
  #
  # The controller is where you define any events you are interested in handling
  # (see add_listener) as well as two special events, the pressing of the "close" button
  # of the window (see close_action), and the updating of the MVC tuple (see update_method).
  # Handlers are methods named according to a certain convention that are the recipient of events.  
  # Handlers are named either <component_event> or just <event> if you want a global handler.  
  # No events are actually generated and sent to the controller unless a listener has been added 
  # for that component, however, component-specific handlers will automatically add a listener 
  # for that component when the class is instantiated.  Therefore a method named 
  # ok_button_action_performed would be the equivalent of 
  # 
  #   add_listener :type => :action, :components => ["ok_button"]
  #   
  # These automatic listener registrations work for any component that can be
  # resolved directly in your view.  In the above example, the view could contain
  # a component named ok_button, okButton or even OkButton and the listener
  # would be added correctly.  If you have a nested component such as text_field.document
  # then you will need to use an explicit add_listener registration.
  # 
  # Global handlers cannot be declared in this fashion, you must use add_listener explicitly.
  # 
  # Handler methods can optionally take one parameter which is the event generated
  # by Swing.  This would look like
  # 
  #   def some_component_event_name(swing_event)
  #
  # While an event handler is running, the Swing Event Dispatch Thread (usually called the EDT)
  # is blocked and as such, no repaint events will occur and no new events will be proccessed.
  # If you have a process that is long running, but you don't want to make asynchronous
  # by spawning a new thread, you can use the repaint_while method which takes a block to execute
  # while still allowing Swing to process graphical events (but not new interaction events like
  # mouse clicking or typing).
  #
  #   def button_action_performed
  #     repaint_while do
  #       sleep(20) # the gui is still responsive while we're in here sleeping
  #       some_component.text = "done sleeping!"
  #     end
  #   end
  # ==========
  #
  # Example of a controller, this assumes the existance of a Ruby class named MyModel that
  # has an attribute named user_name that is mapped to a field on a subclass of 
  # Monkeybars::View named MyView that has a button named "ok_button" and a text field called 
  # user_name
  #
  #   require 'monkeybars'
  #   
  #   class MyController < Monkeybars::Controller
  #     set_view :MyView
  #     set_model :MyModel
  #
  #     close_action :exit
  # 
  #     def ok_button_mouse_released
  #       puts "The user's name is: #{view_state.user_name}"
  #     end
  #   end
  #
  # It is important that you do not implement your own initialize and update methods, this
  # will interfere with the operation of the Controller class (or if you do be sure to call
  # super as the first line).
  class Controller
    include TaskProcessor
    METHOD_NOT_FOUND = :method_not_found
    @@instance_list ||= Hash.new {|hash, key| hash[key] = []}
    @@instance_lock ||= Hash.new {|hash, key| hash[key] = Mutex.new }
    
    # Controllers cannot be instantiated via a call to new, instead use instance
    # to retrieve the instance of the view.  Currently only one instance of a
    # controller is created but in the near future a configurable limit will be
    # available so that you can create n instances of a controller.
    def self.instance
      @@instance_lock[self.class].synchronize do
        controller = @@instance_list[self]
        unless controller.empty?
          controller.last
        else
          __new__
        end
      end
    end
    
    def self.create_instance
      @@instance_lock[self.class].synchronize do
        controllers = @@instance_list[self]
        controllers << __new__
        controllers.last
      end
    end
    
    def self.destroy_instance(controller)
      @@instance_lock[self.class].synchronize do
        controllers = @@instance_list[self]
        controllers.delete controller
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
      begin
        self.view_class = view.constantize
      rescue NameError
        require view.underscore
        self.view_class = view.constantize
      end
    end

    # See set_view.  The declared model class is also auto-required prior to the
    # class being instantiated.
    def self.set_model(model)
      begin
        self.model_class = model.constantize
      rescue NameError
        require model.underscore
        self.model_class = model.constantize
      end
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
    # If you have a single component you can omit the array and pass a single string or symbol.
    # 
    #   add_listener :type => :key, :components => :infoTextField
    #
    # If your component is a nested name, for example
    # 
    #   add_listener :type => :action, :components => "infoTextField.document"
    #   
    # there will be problems when the event is generated and a handler is attempted
    # to be located.  To resolve this, the component name can be a hash, the key
    # being the component name and the value being the desired callback name.
    # 
    #   add_listener :type => :action, :components => {"infoTextField.document" => "info_text_field"}
    #
    # This will cause the info_text_field_action_performed method to be called when
    # the action performed event is generated by infoTextField.document.
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
    #
    # If you wish to override the default event handling behavior, override handle_event
    def self.add_listener(details)
      handlers << details
      hide_protected_class_methods #workaround for JRuby bug #1283
    end
  
    # Declares a method to be called whenever the controller's update method is called.
    def self.set_update_method(method)
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
    #   add_listener :type => :action, :components => [:ok_button]
    #
    # you could implement the handler using:
    #
    #   define_handler(:ok_button_action_performed) do |event|
    #     # handle the event here
    #   end
    #   
    # Note that handlers defined using this method will create implicit listener
    # registrations the same as a declared method would.
    #   
    # define_handler also accepts an array of event names
    #
    #   define_handler([:ok_button_action_performed, :cancel_button_action_performed]) do
    #     # handle event(s) here
    #   end
    def self.define_handler(*actions, &block)
      actions.each {|action| event_handler_procs[action.to_sym] = block}
    end
    
    # Valid close actions are
    # * :nothing
    # * :close (default)
    # * :exit
    # * :dispose
    # * :hide
    #
    # - action :nothing - close action is ignored, this means you cannot
    #   close the window unless you provide another way to do this
    # - action :close - calls the controller's close method
    # - action :exit - closes the application when the window's close
    #   button is pressed    
    # - action :dispose - default action, calls Swing's dispose method which
    #   will release the resources for the window and its components, can be 
    #   brought back with a call to show
    # - action :hide - sets the visibility of the window to false
    def self.set_close_action(action)
      self.send(:class_variable_set, :@@close_action, action)
    end
    
    # Returns a frozen hash of ControllerName => [instances] pairs. This is
    # useful if you need to iterate over all active controllers to call update
    # or to check for a status.
    #
    # # NOTE: Controllers that have close called on them will not show up on this
    # list, even if open is subsequently called. If you need a window to remain
    # in the list but not be updated when not visible you can do:
    #
    #   Monkeybars::Controller.active_controllers.values.flatten.each{|c| c.update if c.visible? }
    def self.active_controllers
      @@instance_list.clone.freeze     
    end
    
    private 
    @@event_handler_procs ||= {}
    def self.event_handler_procs
      @@event_handler_procs[self] ||= {}
    end
    
    @@handlers ||= {}
    def self.handlers
      @@handlers[self] ||= []
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
      @__transfer = {}
      @__registered_handlers = Hash.new{|h,k| h[k] = []}
      @__nested_controllers = {}
      
      unless self.class.handlers.empty?
        if @__view.nil?
          raise "A view must be declared in order to add event listeners"
        end
        
        self.class.handlers.each do |handler|            
          add_handler_for handler[:type], handler[:components]
          handler[:components].each do |component|
            @__registered_handlers[@__view.instance_eval(component.to_s)] << handler[:type].to_s
          end
        end
      end

      methods.grep(/_/).each {|method| add_implicit_handler_for_method(method) }

      self.class.event_handler_procs.each {|method, proc| add_implicit_handler_for_method(method)}
      
      if self.class.class_variables.member?("@@update_method_name")
        begin
          self.class.send(:class_variable_set, :@@update_method, method(self.class.send(:class_variable_get, :@@update_method_name)))
        rescue NameError
          raise "Update method: '#{self.class.send(:class_variable_get, :@@update_method_name)}' was not found for class #{self.class}"
        end  
      end
      
      action = close_action
      unless [:nothing, :close, :exit, :dispose, :hide].include?(action)
        raise "Unknown close action: #{action}.  Only :nothing, :close, :exit, :dispose, and :hide are supported"
      end
      
      window_type = if @__view.instance_variable_get(:@main_view_component).kind_of? javax.swing.JInternalFrame
        "internalFrame"
      else
        "window"
      end
      
      unless @__view.nil?
        @__view.close_action(Monkeybars::View::CloseActions::METHOD, MonkeybarsWindowAdapter.new(:"#{window_type}Closing" => self.method(:built_in_close_method)))
      end
      
      @closed = true
    end
    
    def close_action
      if self.class.class_variables.member?("@@close_action")
        action = self.class.send(:class_variable_get, :@@close_action)
      else
        action = :close
      end
      action
    end
    
    public
    def update
      self.class.send(:class_variable_get, :@@update_method).call if self.class.class_variables.member?("@@update_method_name")
    end

    # Triggers updating of the view based on the mapping and the current contents
    # of the model and the transfer
    def update_view
      @__view.update(model, transfer)
      @__nested_controllers.values.each {|controller_group| controller_group.each {|controller| controller.update_view}}
    end
    
    # Sends a signal to the view.  The view will process the signal (if it is
    # defined in the view via View.define_signal) and optionally invoke the 
    #callback that is passed in as a block.
    #
    # This is useful for communicating one off events such as a state transition
    #
    #   def update
    #     signal(:red_alert) if model.threshold_exceeded?
    #   end
    def signal(signal_name, &callback)
      @__view.process_signal(signal_name, model, transfer, &callback)
    end
    
    # Stores a controller under this one with the given key
    def add_nested_controller(name, sub_controller)
      @__nested_controllers[name] ||= []
      @__nested_controllers[name] << sub_controller
      nested_view = sub_controller.instance_variable_get(:@__view)
      @__view.add_nested_view(name, nested_view, nested_view.instance_variable_get(:@main_view_component), model, transfer)
    end
    
    # Removes the controller with the given name
    def remove_nested_controller(name, sub_controller)
      @__nested_controllers[name].delete sub_controller
    end

    # Returns true if the view is visible, false otherwise
    def visible?
      @__view.visible?
    end

    # Hides the view
    def hide
      @__view.hide
    end
    
    # Disposes the view
    def dispose
      @__view.dispose
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
      @__view.unload unless @__view.nil?
      unload
      @__view.dispose if @__view.respond_to? :dispose
      @@instance_lock[self.class].synchronize do
        @@instance_list[self.class].delete self
      end
    end

    # Calls load if the controller has not been opened previously, then calls update_view
    # and shows the view.
    def open(*args)
      @@instance_lock[self.class].synchronize do
        unless @@instance_list[self.class].member? self
          @@instance_list[self.class] << object
        end
      end
      
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
    def handle_event(component_name, event_name, event) #:nodoc:
      return if event.nil?
      
      proc = get_method("#{component_name}_#{event_name}".to_sym)
      if METHOD_NOT_FOUND == proc
        proc = get_method(event_name.to_sym)
      end
      
      unless METHOD_NOT_FOUND == proc
        0 == proc.arity ? proc.call : proc.call(event)
      end
    end
    
    private
    @@model_class_for_child_controller ||= {}
    def self.model_class
      @@model_class_for_child_controller[self]
    end
    
    def self.model_class=(model)
      @@model_class_for_child_controller[self] = model
    end
    
    @@view_class_for_child_controller ||= {}
    def self.view_class
      @@view_class_for_child_controller[self]
    end
    
    def self.view_class=(view)
      @@view_class_for_child_controller[self] = view
    end
    
    def add_implicit_handler_for_method(method)
      component_match = nil
      Monkeybars::Handlers::ALL_EVENT_NAMES.each do |event|
        component_match = Regexp.new("(.*)_(#{event})").match(method)
        break unless component_match.nil?
      end

      return if component_match.nil?
      component_name, event_name = component_match[1], component_match[2]

      begin
        component = @__view.get_field_value(component_name)
      rescue UndefinedControlError
        # swallow, handlers for controls that don't exist is allowed
      else
        component.methods.each do |method|
          listener_match = /add(.*)Listener/.match(method)
          next if listener_match.nil?
          if Monkeybars::Handlers::EVENT_NAMES_BY_TYPE[listener_match[1]].member? event_name
            add_handler_for listener_match[1], component_name unless @__registered_handlers[component].member? listener_match[1].underscore
          end
        end
      end
    end
    
    def sub_controllers
      @__sub_controllers ||= {}
    end
    
    def model
      @__model
    end
    
    def transfer
      @__transfer      
    end
    
    # This method is almost always used from within an event handler to propogate
    # the view_state to the model. Updates the model from the source provided 
    # (typically from view_state). The list of properties defines what is modified 
    # on the model.
    # 
    #   def ok_button_action_perfomed(event)
    #     view_model, view_transfer = view_state
    #     update_model(view_model, :user_name, :password)
    #   end
    # 
    # This would have the same effect as:
    # 
    #   view_model, view_transfer = view_state
    #   model.user_name = view_model.user_name
    #   model.password = view_model.password
    def update_model(source, *properties)
      properties.each do |property|
        @__model.send("#{property}=", source.send(property))
      end
    end
    
    def update_provided_model(source, destination, *properties)
      properties.each do |property|
        destination.send("#{property}=", source.send(property))
      end
    end
    
    def create_new_model
      self.class.model_class.new
    end
    
    def create_new_view
      self.class.view_class.new
    end
    
    # Returns the contents of the view as defined by the view's mappings.  For use
    # in event handlers.  In an event handler this method is thread safe as Swing
    # is single threaded and blocks any modification to the GUI while the handler
    # is being proccessed.  Each time this method is called the view mappings are
    # called, so if you want to use several model or transfer properties you should
    # save off the return values into a local variable.
    #
    #   def ok_button_action_performed
    #     view_model, view_transfer = view_state
    #     # do various things with view_model or view_transfer here
    #    end
    def view_state
      unless self.class.model_class.nil?
        model = create_new_model 
        @__view.write_state(model, transfer)
        return model, transfer
      else
        nil
      end
    end
    
    def add_handler_for(handler_type, components)
      components = ["global"] if components.nil?
      components = [components] unless components.respond_to? :each
      components.each do |component|
        if component.kind_of? Hash
          component, component_name = component
        else
          component_name = component.to_s
        end
        
        handler = "Monkeybars::#{handler_type.camelize}Handler".constantize.new(self, component_name)
        @__view.add_handler(handler, component)
      end
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
      if event.getID == java.awt.event.WindowEvent::WINDOW_CLOSING
        case close_action
        when :close
          close
        when :exit
          Monkeybars::Controller.active_controllers.values.flatten.each {|c| c.close }
          java.lang.System.exit(0)
        when :hide
          hide
        when :dispose
          dispose
        end
      end
    end
  end

end



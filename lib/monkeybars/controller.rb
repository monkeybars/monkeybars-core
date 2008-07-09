require 'thread'

require "monkeybars/inflector"
require "monkeybars/view"
require "monkeybars/event_handler"
require "monkeybars/task_processor"
require "monkeybars/event_handler_registration_and_dispatch_mixin"

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
  # Handlers are named <component_event>.
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
  #     end
  #     model.text = "done sleeping!"
  #     update_view
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
  #       puts "The user's name is: #{view_state.model.user_name}"
  #     end
  #   end
  #
  # It is important that you do not implement your own initialize and update methods, this
  # will interfere with the operation of the Controller class (or if you do be sure to call
  # super as the first line).
  class Controller
    include TaskProcessor
    include EventHandlerRegistrationAndDispatchMixin
    
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
    
    # Always returns a new instance of the controller. 
    # 
    #   controller = MyController.create_instance
    #   
    # Controllers created this way must be destroyed using
    # Monkeybars::Controller#destroy_instance.
    #
    def self.create_instance
      @@instance_lock[self.class].synchronize do
        controllers = @@instance_list[self]
        controllers << __new__
        controllers.last
      end
    end
    
    # Destroys the instance of the controller passed in.
    # 
    #    MyController.destroy_instance(controller)
    # 
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
      self.view_class = view
    end

    # See set_view.  The declared model class is also auto-required prior to the
    # class being instantiated.  It is not a requirement that you have a model,
    # Monkeybars will operate without one as long as you do not attempt to use
    # methods that interact with the model.
    def self.set_model(model)
      self.model_class = model
    end

    # Declares a method to be called whenever the controller's update method is called.
    def self.set_update_method(method)
      raise "Argument must be a symbol" unless method.kind_of? Symbol
      raise "'Update' is a reserved method name" if :update == method
      self.send(:class_variable_set, :@@update_method_name, method)
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
    
    # See EventHandlerRegistrationAndDispatchMixin::ClassMethods#add_listener
    class << self
       alias_method :original_add_listener, :add_listener
    end
    def self.add_listener(details)
      original_add_listener(details)
      hide_protected_class_methods #workaround for JRuby bug #1283
    end
    
  private
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
      @__model = create_new_model unless self.class.model_class.nil?
      @__view = create_new_view unless self.class.view_class.nil?
      @__transfer = {}
      @__nested_controllers = {}
      @__view_state = nil
      setup_implicit_and_explicit_event_handlers
      
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
    # Calls the method that was set using Controller.set_update_method.  If no method has been set defined, this call is ignored.
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
    
    # Nests a controller under this controller with the given key
    #   def add_user_button_action_performed
    #     @controllers << UserController.create_instance
    #     add_nested_controller(:user_list, @controllers.last)
    #     @controllers.last.open
    #   end
    # This forces the view to perform its nesting.
    # See also Monkeybars::Controller#remove_nested_controller
    #
    def add_nested_controller(name, sub_controller)
      @__nested_controllers[name] ||= []
      @__nested_controllers[name] << sub_controller
      nested_view = sub_controller.instance_variable_get(:@__view)
      @__view.add_nested_view(name, nested_view, nested_view.instance_variable_get(:@main_view_component), model, transfer)
    end
    
    # Removes the nested controller with the given key
    # This does not do any cleanup on the nested controller's instance.
    #
    #   def remove_user_button_action_performed
    #     remove_nested_controller(:user_list, @controllers.last)
    #     UserController.destroy_instance @controllers.last
    #     @controllers.delete @controllers.last
    #   end
    #   
    # This performs the view's nesting.
    # See also Monkeybars::Controller#add_nested_controller
    #
    def remove_nested_controller(name, sub_controller)
      @__nested_controllers[name].delete sub_controller
      nested_view = sub_controller.instance_variable_get(:@__view)
      @__view.remove_nested_view(name, nested_view, nested_view.instance_variable_get(:@main_view_component), model, transfer)
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
          @@instance_list[self.class] << self
        end
      end
      
      if closed?
        load(*args) 
        update_view
        clear_view_state
        @closed = false
      end
      
      show
      
      self #allow var assignment off of open, i.e. screen = SomeScreen.instance.open
    end
    
    # Stub to be overriden in sub-class.  This is where you put the code you would
    # normally put in initialize, it will be called the first time open is called
    # on the controller.
    def load(*args); end

    # Stub to be overriden in sub-class.  This is called whenever the controller is closed.
    def unload; end

    alias_method :original_handle_event, :handle_event
    # See EventHandlerRegistrationAndDispatchMixin#handle_event
    def handle_event(component_name, event_name, event) #:nodoc:
      original_handle_event(component_name, event_name, event)
      clear_view_state
    end
    
    private
    
    # Returns the model object.  This is the object that is passed to the view
    # when update_view is called.  This model is *not* the same model that you
    # get from #view_state.  Values that you want to propogate from the 
    # #view_state model to this model can be done using #update_model.
    def model #:doc:
      @__model
    end
    
    # Returns the transfer object which is a transient hash passed to the view
    # whenever #update_view is called.  The transfer is cleared after each call 
    # to #update_view.  The transfer is used to pass data to and
    # from the view that is not part of your model.  For example, if you had
    # a model that was an ActiveRecord object you would probably not want to
    # put things like the currently selected item into your model.  That data
    # could instead be passed as a value in the transfer.
    # 
    #   transfer[:selected_framework] = "monkeybars"
    #   
    # Then in your view, you could use that transfer value to select the correct
    # value out of a list.
    # 
    #   map :view => "framework_list.selected_item", :transfer => :selected_framework
    #   
    # See View#map for more details on the options for your mapping.
    def transfer #:doc:
      @__transfer      
    end
    
    # Returns a ViewState object which contains a model and a transfer hash of the 
    # view's current contents as defined by the view's mappings.  This is for use in 
    # event handlers. The contents of the model and transfer are *not* the same as 
    # the contents of the model and transfer in the controller, they are new objects
    # created when view_state was called.  If you wish to propogate the values from the 
    # view state's model into the actual model, you must do this yourself.  A 
    # helper method #update_model is provided to make this easier. In an event 
    # handler this method is thread safe as Swing is single threaded and blocks 
    # any modification to the GUI while the handler is being proccessed.  
    # 
    # The view state object has two properties, model and transfer.
    # 
    #   def ok_button_action_performed
    #     if view_state.transfer[:foo] == :bar
    #       model.baz = view_state.model.baz
    #     end
    #   end
    # 
    # Any subsequent call to view_state will return the same object, that is, this
    # method is memoized internally.  At the end of each event (after all handlers
    # have been called) the memoized view state is cleared.  If you call view_state
    # outside of an event handler it is important that you clear the view state 
    # yourself by calling clear_view_state.
    def view_state # :doc:
      return @__view_state unless @__view_state.nil?
      unless self.class.model_class.nil?
        model = create_new_model
        transfer = {}
        @__view.write_state(model, transfer)
        @__view_state = ViewState.new(model, transfer)
      else
        nil
      end
    end
    
    # Equivalent to view_state.model
    def view_model # :doc:
      view_state.model
    end
    
    # Equivalent to view_state.transfer
    def view_transfer
      view_state.transfer
    end
    
    # Resets memoized view_state value. This is called automatically after each
    # event so it would only need to be called if view_state is used outside
    # of an event handler.
    def clear_view_state # :doc:
      @__view_state = nil
    end
    
    # This method is almost always used from within an event handler to propogate
    # the view_state to the model. Updates the model from the source provided 
    # (typically from view_state). The list of properties defines what is modified 
    # on the model.
    # 
    #   def ok_button_action_perfomed
    #     update_model(view_state.model, :user_name, :password)
    #   end
    # 
    # This would have the same effect as:
    # 
    #   model.user_name = view_state.model.user_name
    #   model.password = view_state.model.password
    def update_model(source, *properties) # :doc:
      update_provided_model(source, @__model, *properties)
    end
    
    # This method works just like Controller#update_model except that the target
    # is not implicitly the model.  The second parameter is a target object for
    # the properties to be propogated to.  This is useful if you have a composite
    # model or need to updated other controllers.
    # 
    #   def ok_button_action_perfomed
    #     update_provided_model(view_state.model, model.user, :user_name, :password)
    #   end
    # 
    # This would have the same effect as:
    # 
    #   model.user.user_name = view_state.model.user_name
    #   model.user.password = view_state.model.password
    def update_provided_model(source, destination, *properties) # :doc:
      properties.each do |property|
        destination.send("#{property}=", source.send(property))
      end
    end
    
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
    
    def sub_controllers
      @__sub_controllers ||= {}
    end
    
    def create_new_model
      begin
        self.class.model_class.constantize.new
      rescue NameError
        require self.class.model_class.underscore
        self.class.model_class.constantize.new
      end
    end
    
    def create_new_view
      begin
        self.class.view_class.constantize.new
      rescue NameError
        require self.class.view_class.underscore
        self.class.view_class.constantize.new
      end
    end

    def built_in_close_method(event)
      if event.getID == java.awt.event.WindowEvent::WINDOW_CLOSING || event.getID == javax.swing.event.InternalFrameEvent::INTERNAL_FRAME_CLOSING
        case (action = close_action)
        when :close
          close
        when :exit
          Monkeybars::Controller.active_controllers.values.flatten.each {|c| c.close }
          java.lang.System.exit(0)
        when :hide
          hide
        when :dispose
          dispose
        else
          raise Monkeybars::InvalidCloseAction.new("Invalid close action: #{action}") unless action == :nothing
        end
      end
    end
  end
  
  class InvalidCloseAction < Exception; end

  # A formal object representing the view's model and transfer state.  This used to be 
  # an array so we emulate the array methods that are in common usage.
  class ViewState
    attr_reader :model, :transfer
    
    def initialize(model, transfer)
      @model, @transfer = model, transfer
    end
    
    def [](index)
      case index
      when 0
        @model
      when 1
        @transfer
      else
        nil
      end
    end
    
    def first
      @model
    end
    
    def last
      @transfer
    end
  end
end
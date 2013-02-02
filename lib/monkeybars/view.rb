java_import javax.swing.JComponent
java_import javax.swing.KeyStroke

require 'monkeybars/exceptions'
require 'monkeybars/inflector'
require 'monkeybars/validated_hash'
require 'monkeybars/view_mapping'
require 'monkeybars/task_processor'
require 'monkeybars/view_nesting'
require 'monkeybars/view_positioning'
require "monkeybars/event_handler_registration_and_dispatch_mixin"

module Monkeybars
  # The view is the gatekeeper to the actual Java (or sometimes non-Java) view class.
  # The view defines how data moves into and out of the view via the model.  
  #
  # Any property of the underlying "real" view can be accessed as if it were a
  # property of the view class.
  #
  # Thus if you have a JFrame that has a member variable okButton, you could do
  # the following:
  #
  #   okButton.text = "Confirm"
  #
  # You must use the exact name that is used in the underlying view, no normal
  # JRuby javaName to java_name conversion is performed.  ok_button.text = "Confirm"
  # would fail.
  #
  # Example, (assume a JFrame with a label, text area and button):
  #
  #   require 'monkeybars'
  #
  #   class MyView < Monkeybars::View
  #     set_java_class "com.project.MyCoolJFrame"
  #     map :view => "titleLabel.text", :model => :title_text
  #     map :view => "okButton.text", :model => :button_text
  #     map :view => "mainTextArea.text", :model => :text, :using => [:convert_to_string, :convert_to_array]
  #     map :view => "titleLabel.selected_text_color", :transfer => :text_color
  #     COLOR_TRANSLATION = {:red => Color.new(1.0, 0.0, 0.0), :green => Color.new(0.0, 1.0, 0.0), :blue => Color.new(0.0, 0.0, 1.0)} 
  #     map :view => "titleLabel.selected_text_color", :model => :text, :translate_using => COLOR_TRANSLATION
  #   
  #     def convert_to_string(model) 
  #       model.text.join("\n")
  #     end
  #   
  #     def convert_to_array(model)
  #       mainTextArea.text.split("\n")
  #     end
  #   end
  #
  # It is important that you do not implement your own initialize method, doing so will
  # interfere with the operation of the View class (or if you must, remember to
  # call super on the first line of your initialize).
  #
  # It is possible to have a view that is not related to a Java class, in which
  # case no set_java_class delcaration is used.  If using a pure Ruby view (or
  # manually wrapping a Java class) you must set the @main_view_component
  # member variable yourself.  The object you assign to @main_view_component
  # should respond to any methods that normally interact with the Java object such
  # as visisble?, hide, and dispose
  class View
    include TaskProcessor
    include EventHandlerRegistrationAndDispatchMixin
    include Positioning

    module CloseActions #:nodoc:
      DO_NOTHING = javax::swing::WindowConstants::DO_NOTHING_ON_CLOSE
      DISPOSE = javax::swing::WindowConstants::DISPOSE_ON_CLOSE
      EXIT = javax::swing::WindowConstants::EXIT_ON_CLOSE
      HIDE = javax::swing::WindowConstants::HIDE_ON_CLOSE
      METHOD = :method
    end

    private
    @@view_nestings_for_child_view ||= {}
    def self.view_nestings
      @@view_nestings_for_child_view[self] ||= {}
    end

    @@view_mappings_for_child_view ||= {}   
    def self.view_mappings
      @@view_mappings_for_child_view[self] ||= []
    end

    @@java_class_for_child_view ||= {}
    def self.instance_java_class
      @@java_class_for_child_view[self]
    end

    def self.instance_java_class=(java_class)
      @@java_class_for_child_view[self] = java_class
    end

    @@signal_mappings ||= {}
    def self.signal_mappings
      @@signal_mappings[self] ||= {}
    end

    public
    # Declares what class to instantiate when creating the view.  Any listeners
    # set on the component are added to this class as well as the setting of the
    # close action that is defined in the controller.
    # Accepts a string that is the Java package, or a class for the Java or JRuby UI object
    def self.set_java_class(java_class)
      # We're allowing two options: The existing "Give me a string", and
      # passing a constant (which is new behavior).
      # In a view class, the develoepr can simply give the name of a defined class
      # to use, in which case this code does not need to try to load anything.
      if java_class.is_a?(String)
        java_import java_class
        class_name = /.*?\.?(\w+)$/.match(java_class)[1]
        self.instance_java_class = const_get(class_name)
      elsif  java_class.is_a?(Class)
        self.instance_java_class = java_class
      else
        raise "Setting the view class requires either a string naming the class to load, or an actual class constant. set_java_class was given #{java_class.inspect}."
      end
    end

    # Declares a mapping between the properties of the view and either the model's 
    # or the transfer's properties.  This mapping is used when creating the model.
    # If you wish to trigger subsequent updates of the view, you may call 
    # update_view manually from the controller.
    #
    # There are several ways to declare a mapping based on what level of control
    # you need over the process.  The simplest form is:
    #
    #   map :view => :foo, :model => :bar
    #   
    #   or
    #   
    #   map :view => :foo, :transfer => :bar
    #
    # Which means, when update is called, self.foo = model.bar and 
    # self.foo = transfer[:bar] respectively.
    #
    # Strings may be used interchangably with symbols for model mappings.  If you 
    # have nested view or properties you may specify them as a string:
    #
    #   map :view => "foo.sub_property", :model => "bar.other_sub_property"
    #
    # which means, self.foo.sub_property = model.bar.other_sub_property
    #
    # It should be noted that these mappings are bi-directional.  They are 
    # referenced for both update and write_state.  When used
    # for write_state the assignment direction is reversed, so a view with
    #
    #   map :view => :foo, :model => :bar
    #
    # would mean model.bar = self.foo
    # 
    # When a direct assignment is not sufficient you may provide a method to
    # filter or adapt the contents of the model's value before assignment to
    # the view.  This is accomplished by adding a :using key to the hash.
    # The key's value is an array of the method names to be used when converting from
    # the model to the view, and when converting from the view back to the model.  
    # If you only want to use a custom method for either the conversion from a model 
    # to a view or vice versa, you can specify :default, for the other parameter 
    # and the normal mapping will take place.  If you want to disable the copying
    # of data in one direction you can pass nil as the method parameter.
    #
    #   map :view => :foo, :model => :bar, :using => [:from_model, :to_model]
    #
    # would mean self.foo = from_model() when called by update and
    # model.bar = to_model() when called by write_state.
    # 
    #   map :view => :foo, :model => :bar, :using => [:from_model, :default]
    #   
    # would mean self.foo = from_model() when called by update and
    # model.bar = self.foo when called by write_state.
    #
    #   map :view => :foo, :model => :bar, :using => [:from_model, nil]
    #   
    # would mean self.foo = from_model() when called by update and
    # would do nothing when called by write_state.
    # 
    # For constant value translation, :translate_using provides a one-line approach.
    # :translate_using takes a hash with the model values as the key, and the view values as the value.
    # This only works when the view state and the model state has a one-to-one translation.
    # 
    #   COLOR_TRANSLATION = {:red => Color.new(1.0, 0.0, 0.0), :green => Color.new(0.0, 1.0, 0.0), :blue => Color.new(0.0, 0.0, 1.0)} 
    #   map :view => "titleLabel.selected_text_color", :model => :text, :translate_using => COLOR_TRANSLATION
    #
    # If you want to invoke disable_handlers during the call to update
    # you can add the :ignoring key.  The key's value is either a single type or
    # an array of types to be ignored during the update process.
    # 
    #   map :view => :foo, :model => :bar, :ignoring => :item
    # 
    # This will wrap up the update in a call to disable_handlers on the view 
    # component, which is assumed to be the first part of the mapping UP TO THE 
    # FIRST PERIOD.  This means that
    # 
    #   map :view => "foo.bar", :model => :model_property, :ignoring => :item
    # 
    # would translate to
    # 
    #   foo.disable_handlers(:item) do
    #     foo.bar = model.model_property
    #   end
    #   
    # during a call to update.  During write_to_model, the ignoring
    # definition has no meaning as there are no event handlers on models.
    #
    # The final option for mapping properties is a simply your own method.  As with
    # a method provided via the using method you may provide a method for conversion
    # into the view, out of the view or both.
    #
    #   raw_mapping :from_model, :to_model
    #
    # would simply invoke the associated method when update or 
    # write_state was called.  Thus any assignment to view properties
    # must be done within the method (hence the 'raw').
    #
    # To disable handlers in a raw mapping, call Component#disable_handlers
    # inside your mapping method
    #
    def self.map(properties)
      mapping = Mapping.new(properties)
      view_mappings << mapping
    end

    # See View.map
    def self.raw_mapping(to_view_method, from_view_method, handlers_to_ignore = [])
      view_mappings << Mapping.new(:using => [to_view_method, from_view_method], :ignoring => handlers_to_ignore)
    end

    # Declares a mapping between a signal and a method to process the signal.  When 
    # the signal is received, the method is called with the model and the transfer as parameters.
    # If a signal is sent that is not defined, an UnknownSignalError exception is raised.
    #
    #   define_signal :name => :error_state, :handler => :disable_go_button
    # 
    #   def disable_go_button(model, transfer)
    #     go_button.enabled = false
    #   end
    #
    def self.define_signal(options, method_name = nil)
      if options.kind_of? Hash
        begin
          options.validate_only :name, :handler
          options.validate_all  :name, :handler
        rescue InvalidHashKeyError
          raise InvalidSignalError, ":signal and :handler must be provided for define_signal. Options provided: #{options.inspect}"
        end
        signal_mappings[options[:name]] = options[:handler]
      else
        #support two styles for now, deprecating the old (signal, method_name) style      
        warn "The usage of define_signal(signal, method_name) has been deprecated, please use define_signal :name => :signal, :handler => :method_name"
        signal_mappings[options] = method_name
      end

    end

    # Declares how nested views from their respective nested controllers are to be
    # added and removed from the view. Multiple nestings for the different nested
    # controllers are possible through the :sub_view value, which is basically a grouping
    # name. Two kinds of mapping are possible: A property nesting, and a method nesting.
    # Property nesting:
    # 
    #   nest :sub_view => :user_list, :view => :user_panel
    #   
    # This essentially calls user_panel.add nested_view_component on Monkeybars::Controller#add_nested_controller
    # and user_panel.remove nested_view_componenent on Monkeybars::Controller#remove_nested_controller.
    # A layout on the container being used is preferred, as no orientational information will be conveyed
    # to either component.
    # 
    # Method nesting:
    #   
    #   nest :sub_view => :user_list, :using => [:add_user, :remove_user]
    # 
    #   def add_user(nested_view, nested_component, model, transfer)
    #     user_panel.add nested_component
    #     nested_component.set_location(nested_component.x, nested_component.height * transfer[:user_list_size])
    #   end
    #   
    #   def remove_user(nested_view, nested_component, model, transfer)
    #     # nested_view is the Ruby view object
    #     # nested_component is the Java form, aka @main_view_component
    #     
    #     user_panel.remove nested_component
    #     # lots of code to re-order previous components
    #   end
    # 
    # Method nesting calls the methods in :using (in the same way that :using works for mapping) during
    # add and remove (Monkeybars::Controller#add_nested_controller and Monkeybars::Controller#remove_nested_controller).
    # Both methods are passed in the view, the view's main view component, the mode, and the transfer, respectively.
    #
    # New users using Netbeans will need to know that the GroupLayout (aka FreeDesign) is a picky layout that demands
    # constraints while adding components. By default, all containers use GroupLayout in Netbeans's GUI builder. If you're
    # not sure what all this means, just start off with a BoxLayout (which is not picky). If your layout needs constraints,
    # you will need to pass them in with your Method Nesting. Some layouts even need @main_view_component#revalidate to be
    # called. In short, be aware of Swing's quirks.
    def self.nest(properties)
      view_nestings[properties[:sub_view]] ||= []
      view_nestings[properties[:sub_view]] << Nesting.new(properties)
    end

    def initialize
      @__field_references = {}
      # We have at three possibilities:
      #  - The UI form is a Java class all the way; that it, it came from Java code compiled into a .class file.
      #  - The UI form was written in Ruby, but inherits from a Java class (e.g. JFrame). It is quite servicable
      #    for the UI, but will behave differently in regards to Java reflection -- We'll refer to this as a JRuby class
      #  - The UI form is not Java at all. 
      @main_view_component = create_main_view_component
      raise MissingMainViewComponentError, "Missing @main_view_component. Use View.set_java_class or override create_main_view_component." if @main_view_component.nil?
      @is_java_class = !@main_view_component.class.respond_to?(:java_proxy_class)
      setup_implicit_and_explicit_event_handlers
      load
    end

    # This is set via the constructor, do not call directly unless you know what
    # you are doing.
    #
    # Defines the close action for a visible window.  This method is only applicable
    # for JFrame or decendants, it is ignored for all other classes.
    #
    # close_action expects an action from Monkeybars::View::CloseActions
    #
    # The CloseActions::METHOD action expects a second parameter which should be a
    # MonkeybarsWindowAdapter.
    def close_action(action, handler = nil)
      if @main_view_component.kind_of?(javax.swing.JFrame) || @main_view_component.kind_of?(javax.swing.JInternalFrame) || @main_view_component.kind_of?(javax.swing.JDialog)
        if CloseActions::METHOD == action
          @main_view_component.default_close_operation = CloseActions::DO_NOTHING
          unless @main_view_component.kind_of?(javax.swing.JInternalFrame)
            @main_view_component.add_window_listener(handler)
          else
            @main_view_component.add_internal_frame_listener(handler)
          end
        else
          @main_view_component.set_default_close_operation(action)
        end
      end
    end

    # This method is called when Controller#load has completed (usually during Controller#open)
    # but before the view is shown.  This method is meant to be overriden in views that
    # need control over how their mappings are initially run.  By overriding this method
    # you could use disable_handlers to disable certain handlers during the
    # initial mapping process or perform some actions after the mappings complete.
    #
    # When overriding on_first_update, you must at some point make a call to
    # super or the View#update method in order for your view's mappings to be invoked.
    def on_first_update(model, transfer)
      update(model, transfer)
    end

    def visible?
      return @main_view_component.visible
    end

    def visible=(visibility)
      @main_view_component.visible = visibility
    end

    def show
      @main_view_component.visible = true
    end

    def hide
      @main_view_component.visible = false
    end

    # This is set via the controller, do not call directly unless you know what
    # you are doing.
    #
    # Looks up the appropriate component and calls addXXXListener on the
    # component.  Components can be nested, so textField.document would be a valid
    # component and the listner would be added to the document object of the text
    # field.
    #
    # add_handler returns a hash of objects as keys and their normalized (underscored
    # and . replaced with _ ) names as values
    def add_handler(handler, component)
      component = component.to_s
      if "global" == component
        raise "Global handler declarations are not yet supported"
      elsif "java_window" == component
        begin
          @main_view_component.send("add#{handler.type.camelize}Listener", handler)
        rescue NameError
          raise InvalidHandlerError, "There is no listener of type #{handler.type} on #{@main_view_component}"
        end
      else
        begin
          object = instance_eval(component, __FILE__, __LINE__)
        rescue NameError
          raise UndefinedComponentError, "Cannot add #{handler.type} handler to #{component} on #{self}, the component could not be found"
        end

        begin        
          object.send("add#{handler.type.camelize}Listener", handler)
        rescue NameError
          raise InvalidHandlerError, "There is no listener of type #{handler.type} on #{component}"
        end
      end
    end

    # Attempts to find a member variable in the underlying @main_view_component
    # object if one is set, otherwise falls back to default method_missing implementation.
    #
    # Also, detect if the user is trying to set a new value for a given instance
    # variable in the form.  If so, the field will be updated to refer to the provided
    # value.  The passed in argument MUST BE A JAVA OBJECT or this call will fail.
    def method_missing(method, *args, &block)
      if match = /(.*)=$/.match(method.to_s)
        if @is_java_class
          field = get_field(match[1])
          field.set_value(Java.ruby_to_java(@main_view_component), Java.ruby_to_java(args[0]))
        else
          set_jruby_field(match[1], args[0])
        end
      else
        begin
          return get_field_value(method)
        rescue NameError
          super
        end
      end
    end

    def set_jruby_field(getter, value)
      @main_view_component.send("#{getter}=", value)
    end

    def add_nested_view(nested_name, nested_view, nested_component, model, transfer) #:nodoc:
      self.class.view_nestings[nested_name].select{|nesting| nesting.nests_with_add?}.each {|nesting| nesting.add(self, nested_view, nested_component, model, transfer)}
    end

    def remove_nested_view(nested_name, nested_view, nested_component, model, transfer) #:nodoc:
      self.class.view_nestings[nested_name].select{|nesting| 
        nesting.nests_with_remove?
      }.each {|nesting| 
        nesting.remove(self, nested_view, nested_component, model, transfer) 
      }
    end

    # True if the controller's view is focused. Focus mostly means this is the window where mouse clicks and keyboard presses are directed.
    # There are also UI effects for focused components.
    # For event driven notifications of focus, see the following:
    # http://java.sun.com/j2se/1.4.2/docs/api/java/awt/event/FocusListener.html
    # http://java.sun.com/docs/books/tutorial/uiswing/events/focuslistener.html
    # http://java.sun.com/docs/books/tutorial/uiswing/misc/focus.html
    def focused?
      @main_view_component.focus_owner?
    end

    def update(model, transfer)
      self.class.view_mappings.select{|mapping| mapping.maps_to_view?}.each {|mapping| mapping.to_view(self, model, transfer)}
      transfer.clear
    end

    # The inverse of update.  Called when view_state is called in the controller.
    def write_state(model, transfer)
      transfer.clear
      self.class.view_mappings.select{|mapping| mapping.maps_from_view?}.each {|mapping| mapping.from_view(self, model, transfer)}
    end

    def process_signal(signal, model, transfer, &block)
      handler = self.class.signal_mappings[signal]
      if handler.nil?
        raise UndefinedSignalError, "There is no signal '#{signal}' defined"
      else
        raise InvalidSignalHandlerError, "There is no handler method '#{handler}' on view #{self.class}" unless respond_to?(handler)
        self.send(handler, model, transfer, &block) unless handler.nil?
      end
    end

    # Stub to be overriden in sub-class.  This is where you put the code you would
    # normally put in initialize.  Load will be called whenever a new class is instantiated
    # which happens when the Controller's instance method is called on a non-instantiated
    # controller.  Thus this method will always be called before the Controller's
    # load method (which is called during Controlller#open).
    def load; end

    # Stub to be overriden in sub-class.  This is called whenever the view is closed.
    def unload; end

    # Uses get_field to retrieve the value of a particular field, this is typically
    # a component on a Java form. Used internally by method missing to enable:
    #
    #   some_component.method
    def get_field_value(field_name)
      if "java_window" == field_name.to_s
        @main_view_component
      else
        field_name = field_name.to_sym
        if @is_java_class
          field_object = get_field(field_name)
          Java.java_to_ruby(field_object.value(Java.ruby_to_java(@main_view_component)))
        else
          get_field(field_name).call
        end
      end
    end

    # Uses reflection to pull a private field out of the Java objects.  In cases where
    # no Java object is being used, the view object itself is referenced. A field
    # is not the same as the object it refers to, you only need this method if you
    # want to change what a view field references using the set_value method.
    #
    # field = get_field("my_button")
    # field.set_value(Java.ruby_to_java(@main_view_component), Java.ruby_to_java(my_new_button))
    def get_field(field_name)
      field_name = field_name.to_sym
      field = @__field_references[field_name]

      if field.nil?
        if @is_java_class
          [field_name.to_s, field_name.camelize, field_name.camelize(false), field_name.underscore].uniq.each do |name|
            begin
              field = self.class.instance_java_class.java_class.declared_field(name)
            rescue NameError, NoMethodError
            end
            break unless field.nil?
          end
          raise UndefinedComponentError, "There is no component named #{field_name} on view #{@main_view_component.class}" if field.nil?

          field.accessible = true
        else
          begin
            field = @main_view_component.method(field_name)
          rescue NameError, NoMethodError
            raise UndefinedComponentError, "There is no component named #{field_name} on view #{@main_view_component.class}"
          end
        end
        @__field_references[field_name] = field
      end
      field
    end

    def dispose
      @main_view_component.dispose if @main_view_component.respond_to? :dispose
    end

    def get_field_names
      fields = []
      if @is_java_class
        klass = self.class.instance_java_class.java_class
        while(klass.name !~ /^java[x]?\./)
          fields << klass.declared_fields
          klass = klass.superclass
        end
        fields.flatten.map! {|field| field.name }
      else
        @main_view_component.send(:instance_variables).map! {|name| name.sub('@', '')}
      end
    end

    private
    # Creates and returns the main view component to be assigned to @main_view_component.
    # Override this when a non-default constructor is needed.
    def create_main_view_component
      self.class.instance_java_class.new if self.class.instance_java_class.respond_to?(:new)
    end
    
    # Retrieves all the components on the main view. This will work even if
    # @main_view_component is not a Java object as long as it implements
    # a components method.
    def get_all_components(list = [], components = @main_view_component.components)
      components.each do |component|
        list << component
        get_all_components(list, component.components) if component.respond_to? :components
      end
      list
    end
  end

end

class InvalidSignalError < Exception; end
class MissingMainViewComponentError< Exception; end

module HandlerContainer
  # Removes the handlers associated with a component for the duration of the block.
  # All handlers are re-added to the component afterwards.
  #
  #   some_text_field.disable_handlers(:action, :key) do
  #     # some code that we don't want to trigger action listener methods or key listener methods for
  #   end
  #
  def disable_handlers(*types)
    types.map! { |t| t.camelize }
    listeners = {}
    types.each do |type|  
      listener_class = if Monkeybars::Handlers::AWT_TYPES.member?(type)
                         instance_eval("java.awt.event.#{type}Listener", __FILE__, __LINE__)
                       elsif Monkeybars::Handlers::SWING_TYPES.member?(type)
                         instance_eval("javax.swing.event.#{type}Listener", __FILE__, __LINE__)
                       elsif Monkeybars::Handlers::BEAN_TYPES.member?(type)
                         instance_eval("java.beans.#{type}Listener", __FILE__, __LINE__)
                       end
      listeners[type] = self.get_listeners(listener_class.java_class)
      listeners[type].each do |listener|
        self.send("remove#{type}Listener", listener)
      end 
    end
    yield
    types.each do |type|
      listeners[type].each do |listener|
        self.send("add#{type}Listener", listener)
      end 
    end
  end
end

PlainDocument = javax.swing.text.PlainDocument
class PlainDocument
  include HandlerContainer
end

Component = java.awt.Component
# The java.awt.Component class is opened and a new method is added to allow
# you to ignore certain events during a call to update_view.
class Component
  include HandlerContainer
end

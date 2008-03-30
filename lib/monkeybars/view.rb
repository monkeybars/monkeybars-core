include_class javax.swing.JComponent
include_class javax.swing.KeyStroke

require "monkeybars/inflector"
require 'monkeybars/validated_hash'
require 'monkeybars/view_mapping'
require 'monkeybars/task_processor'
require 'monkeybars/view_nesting'

module Monkeybars
  class UndefinedControlError < Exception; end
  class InvalidSignalHandlerError < Exception; end

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
    # set on the controller are added to this class as well as the setting of the
    # close action that is defined in the controller.
    def self.set_java_class(java_class)
      include_class java_class
      class_name = /.*?\.?(\w+)$/.match(java_class)[1]
      self.instance_java_class = const_get(class_name)
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
    #   map :view => :foo, :method => :bar, :using => [:from_model, :to_model]
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
    def self.map(properties)
      mapping = Mapping.new(properties)
      view_mappings << mapping
    end
    
    # See View.map
    def self.raw_mapping(to_view_method, from_view_method, handlers_to_ignore = [])
      view_mappings << Mapping.new(:using => [to_view_method, from_view_method], :ignoring => handlers_to_ignore)
    end
    
    # Declares a mapping between a signal and a method to process the signal.  Only
    # signals that are declared are processed.
    def self.define_signal(signal, method_name)
      signal_mappings[signal] = method_name
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
    #     user_panel.remove nested_component
    #     # lots of code to re-order previous components
    #   end
    # 
    # Method nesting calls the methods in :using (in the same way that :using works for mapping) during
    # add and remove (Monkeybars::Controller#add_nested_controller and Monkeybars::Controller#remove_nested_controller).
    # Both methods are passed in the view, the view's main view component, the mode, and the transfer, respectively.
    # 
    def self.nest(properties)
      view_nestings[properties[:sub_view]] ||= []
      view_nestings[properties[:sub_view]] << Nesting.new(properties)
    end
    
    def initialize
      @__field_references = {}
      
      @@is_a_java_class = !self.class.instance_java_class.nil? && self.class.instance_java_class.ancestors.member?(java.lang.Object)
      if @@is_a_java_class
        @main_view_component = self.class.instance_java_class.new
#        fields = self.class.instance_java_class.java_class.declared_fields
#        fields.each do |declared_field|
#          field = get_field_value(declared_field.name)
#          field.name = declared_field.name if field.kind_of?(java.awt.Component)
#        end
      end
      
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
        @main_view_component.send("add#{handler.type.camelize}Listener", handler)
      else
        object = instance_eval(component, __FILE__, __LINE__)
        object.send("add#{handler.type.camelize}Listener", handler)
      end
    end
    
    # Attempts to find a member variable in the underlying @main_view_component
    # object if one is set, otherwise falls back to default method_missing implementation.
    def method_missing(method, *args, &block)
      begin
        return get_field_value(method)
      rescue NameError
        super
      end
    end
    
    def add_nested_view(nested_name, nested_view, nested_view_component, model, transfer)
      self.class.view_nestings[nested_name].select{|nesting| nesting.nests_with_add?}.each {|nesting| nesting.add(self, nested_view, nested_view_component, model, transfer)}
    end
    
    def remove_nested_view(nested_name, model, transfer)
      self.class.view_nestings[nested_name].select{|nesting| nesting.nests_with_remove?}.each {|nesting| nesting.remove(self, model, transfer)}
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
      raise InvalidSignalHandlerError, "There is no handler method '#{handler}' on view #{self.class}" unless respond_to? handler
      self.send(handler, model, transfer, &block) unless handler.nil?
    end
    
    # Stub to be overriden in sub-class.  This is where you put the code you would
    # normally put in initialize, it will be called whenever a new class is instantiated
    def load; end
    
    # Stub to be overriden in sub-class.  This is called whenever the view is closed.
    def unload; end

    # Uses get_field to retrieve the value of a particular field, this is typically
    # a control on a Java form. Used internally by method missing to enable:
    #
    #   someControl.method
    def get_field_value(field_name)
      if "java_window" == field_name.to_s
        @main_view_component
      else
        field_name = field_name.to_sym
        if @@is_a_java_class
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
    # want to change what a view field references.
    def get_field(field_name)
      field_name = field_name.to_sym
      field = @__field_references[field_name]
      
      if field.nil?
        if @@is_a_java_class
          [field_name.to_s, field_name.camelize, field_name.camelize(false), field_name.underscore].uniq.each do |name|
            begin
              field = self.class.instance_java_class.java_class.declared_field(name)
            rescue NameError, NoMethodError
            end
            break unless field.nil?
          end
          raise UndefinedControlError, "There is no control named #{field_name} on view #{@main_view_component.class}" if field.nil?
          
          field.accessible = true
        else
          field = method(field_name)
        end
        @__field_references[field_name] = field
      end
      field
    end
    
    def dispose
      @main_view_component.dispose
    end
    
    private
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


module HandlerContainer
  # Removes the handlers associated with a control for the duration of the block.
  # All handlers are re-added to the component afterwards.
  #
  #   some_text_field.disable_handlers(:action, :key) do
  #     # some code that we don't want to trigger action and key handlers for
  #   end
  #
  def disable_handlers(*types)
    types.map! { |t| t.camelize }
    listeners = {}
    types.each do |type|  
      listener_class = Monkeybars::Handlers::AWT_TYPES.member?(type) ? instance_eval("java.awt.event.#{type}Listener", __FILE__, __LINE__) : instance_eval("javax.swing.event.#{type}Listener", __FILE__, __LINE__)
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

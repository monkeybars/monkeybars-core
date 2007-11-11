include_class javax.swing.JComponent
include_class javax.swing.KeyStroke

require "monkeybars/inflector"

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
  #   class MyView < Monkeybars::View
  #     set_java_class "com.project.MyCoolJFrame"
  #     map("titleLabel.text").to(:title_text)
  #     map("okButton.text").to(:button_text)
  #     map("mainTextArea.text").to(:text).using(:convert_to_string, :convert_to_array)
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
  # interfere with the operation of the View class.
  #
  # It is possible to have a view that is not related to a Java class, in which
  # case no set_java_class delcaration is used.  If using a pure Ruby view (or
  # manually wrapping a Java class) you must set the @main_view_component
  # member variable yourself.  The object you assign to @main_view_component
  # should respond to any methods that normally interact with the Java object such
  # as visisble?, hide, and dispose
  class View
    # This is an internal class used only by View
    #
    # A ModelMapping records the relationship between the fields of a model and
    # the fields of a view.  Mappings are created for each call to View.map and
    # are cached until the view is instantiated.  The mappings are then inspected
    # for validity and are assigned a type (one of the constants defined in
    # ModelMapping) to speed up processing.  Invalid mappings raise an exception.
    class ModelMapping #:nodoc:
      TYPE_RAW = :raw
      TYPE_PROPERTIES = :both_properties
      TYPE_METHOD = :method
      DIRECTION_IN = :in
      DIRECTION_OUT = :out
      DIRECTION_BOTH = :both
      
      attr_accessor :view_property, :model_property, :in_method, :out_method, :type, :direction, :event_types_to_ignore
      
      def initialize(view_property = nil, model_property = nil)
	@view_property = view_property
        @model_property = model_property
        @in_method = nil
        @out_method = nil
        @event_types_to_ignore = []
      end
      
      def to(model_property)
        @model_property = model_property
        return self
      end

      def using(in_method, out_method)
        @in_method = in_method
        @out_method = out_method
        return self
      end
      
      def ignoring(*event_types)
      	@event_types_to_ignore = event_types
      end
      
      def properties_only?
        (at_least_one_property_present? and !at_least_one_method_present?) ? true : false
      end
      
      def both_properties_and_methods?
	(both_properties_present? and at_least_one_method_present?) ? true : false
      end
      
      def methods_only?
	(!at_least_one_property_present? and at_least_one_method_present?)  ? true : false
      end
      
      def both_properties_present?
	!@view_property.nil? and !@model_property.nil?
      end

      def both_methods_present?
	!@in_method.nil? and !@out_method.nil?
      end

      def in_method_present?
	!@in_method.nil?
      end
      
      def out_method_present?
	!@out_method.nil?
      end
      
      private
      
      def at_least_one_property_present?
	!@view_property.nil? or !@model_property.nil?
      end
      
      def at_least_one_method_present?
	!@in_method.nil? or !@out_method.nil?
      end
    end
    
    module CloseActions #:nodoc:
      DO_NOTHING = javax::swing::WindowConstants::DO_NOTHING_ON_CLOSE
      DISPOSE = javax::swing::WindowConstants::DISPOSE_ON_CLOSE
      EXIT = javax::swing::WindowConstants::EXIT_ON_CLOSE
      HIDE = javax::swing::WindowConstants::HIDE_ON_CLOSE
      METHOD = :method
    end
    
    private
    @@view_mappings_for_child_view = {}   
    def self.view_mappings
      @@view_mappings_for_child_view[self] ||= []
    end
    
    @@java_class_for_child_view = {}
    def self.instance_java_class
      @@java_class_for_child_view[self]
    end
    
    def self.instance_java_class=(java_class)
      @@java_class_for_child_view[self] = java_class
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
    
    # Declares a mapping between the controller's model's properties and
    # properties of the view.  This mapping is used when creating the model.
    # If you wish to trigger subsequent updates of the view, you may call 
    # update_from_model manually from the controller.
    #
    # PENDING: There will soon be an option to specify a mapping as recurring
    # at a specified time interval (every 10 seconds, every 100 ms, etc.).
    #
    # There are several ways to declare a mapping based on what level of control
    # you need over the process.  The simplest form is:
    #
    #   map(:foo).to(:bar)
    #
    # Which means, when update_from_model is called, self.foo = model.bar
    #
    # Strings may also be used interchangably with symbols.  If you have nested
    # properties you may specify them as a string:
    #
    #   map("foo.sub_property").to("bar.other_sub_property")
    #
    # which means, self.foo.sub_property = model.bar.other_sub_property
    #
    # It should be noted that these mappings are bi-directional.  They are 
    # referenced for both update_from_model and write_state_to_model.  When used
    # for write_state_to_model the assignment direction is reversed, so a view with
    #
    #   map(:foo).to(:bar)
    #
    # would mean model.bar = self.foo
    # 
    # When a direct assignment is not sufficient you may provide a method to
    # filter or adapt the contents of the model's value before assignment to
    # the view.  This is accomplished by adding a .using call after the .to call.
    # The parameters are the methods to be used when converting from the model 
    # to the view, and when converting from the view back to the model.  If you
    # only want to use a custom method for either the conversion from a model to
    # a view or vice versa, you can specify :default, for the other parameter 
    # and the normal mapping will take place.  If you want to disable the copying
    # of data in one direction you can pass nil as the method parameter.
    #
    #   map(:foo).to(:bar).using(:from_model, :to_model)
    #
    # would mean self.foo = from_model() when called by update_from_model and
    # model.bar = to_model() when called by write_state_to_model.
    # 
    #   map(:foo).to(:bar).using(:from_model, :default)
    #   
    # would mean self.foo = from_model() when called by update_from_model and
    # model.bar = self.foo when called by write_state_to_model.
    #
    #   map(:foo).to(:bar).using(:from_model, nil)
    #   
    # would mean self.foo = from_model() when called by update_from_model and
    # would do nothing when called by write_state_to_model.
    #
    # If you want to invoke disable_handlers during the call to update_from_model
    # you can add .ignore(type or array of types).
    # 
    #   map(:foo).to(:bar).ignoring(:item)
    # 
    # This will wrap up the update in a call to disable_handlers on the view 
    # component, which is assumed to be the first part of the mapping UP TO THE 
    # FIRST PERIOD.  This means that
    # 
    #   map("foo.bar").to(:model_property).ignoring(:item)
    # 
    # would translate to
    # 
    #   foo.disable_handlers(:item) do
    #     foo.bar = model.model_property
    #   end
    #   
    # during a call to update_from_model.  During write_to_model, the ignoring
    # definition has no meaning as there are no event handlers on models.
    #
    # The final option for mapping properties is a simply your own method.  As with
    # a method provided via the using method you may provide a method for conversion
    # into the view, out of the view or both.
    #
    #   raw_mapping(:from_model, :to_model)
    #
    # would simply invoke the associated method when update_from_model or 
    # write_state_to_model was called.  Thus any assignment to view properties
    # must be done within the method (hence the 'raw').
    def self.map(view_property)
      mapping = ModelMapping.new(view_property)
      view_mappings << mapping
      return mapping
    end
    
    # See View.map
    def self.raw_mapping(in_method, out_method)
      mapping = ModelMapping.new
      mapping.in_method = in_method
      mapping.out_method = out_method
      view_mappings << mapping
      nil #prevent accidental raw_mapping().something calls
    end
    
    def initialize
      @__field_references = {}
      @@is_a_java_class = !self.class.instance_java_class.nil? && self.class.instance_java_class.ancestors.member?(java.lang.Object)
      if @@is_a_java_class
        @main_view_component = self.class.instance_java_class.new
        fields = self.class.instance_java_class.java_class.declared_fields
        fields.each do |declared_field|
          field = get_field_value(declared_field.name)
          field.name = declared_field.name if field.kind_of?(java.awt.Component)
        end
      end
      
      validate_mappings

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
      if @main_view_component.kind_of?(javax.swing.JFrame) || @main_view_component.kind_of?(javax.swing.JInternalFrame)
        if :method == action
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

    def dispose
      @main_view_component.dispose
    end
    
    # For internal use.
    # This is set via the controller, do not call directly unless you know what
    # you are doing.
    def add_handler(type, handler, components)
      components = ["global"] if components.nil?
      components.each do |component|
        if "global" == component
          get_all_components.each do |component|
            component.send("add#{type.camelize}Listener", handler)
          end
        elsif "java_window" == component.to_s
          @main_view_component.send("add#{type.camelize}Listener", handler)
        else
          get_field_value(component).send("add#{type.camelize}Listener", handler)
        end
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
    
    # This method is called when the view is initialized.  It uses the mappings
    # rules declared in the view to copy data from the supplied model into the view.
    def update_from_model(model)
      return if model.nil?
      mapping_proc = Proc.new do |mapping|
        begin
          if [View::ModelMapping::DIRECTION_IN, View::ModelMapping::DIRECTION_BOTH].member? mapping.direction
            case mapping.type
            when View::ModelMapping::TYPE_PROPERTIES
              map_model_properties_to_view(mapping, model)
            when View::ModelMapping::TYPE_METHOD
              if :default == mapping.in_method
                map_model_properties_to_view(mapping, model)
              else
                instance_eval("self.#{mapping.view_property.to_s} = method(mapping.in_method).call(model)")
              end
            when View::ModelMapping::TYPE_RAW
              method(mapping.in_method).call(model)
            end
          end
        rescue NoMethodError => e
          raise InvalidMappingError, "Invalid mapping #{mapping.inspect} in class #{self.class}, #{e.message}"
        end
      end
      @__valid_mappings.each do |mapping|
        if mapping.event_types_to_ignore.empty?
          mapping_proc.call(mapping)
        else
          get_field_value(/^(\w+)\.?/.match(mapping.view_property)[1]).disable_handlers(mapping.event_types_to_ignore[0]) { mapping_proc.call(mapping) }
        end
      end
    end
    
    # The inverse of update_from_model.  Called when an event is generated and
    # the controller needs the state of the view.
    def write_state_to_model(model)
      @__valid_mappings.each do |mapping|
        if [View::ModelMapping::DIRECTION_OUT, View::ModelMapping::DIRECTION_BOTH].member? mapping.direction
          case mapping.type
          when View::ModelMapping::TYPE_PROPERTIES
            map_view_properties_to_model(mapping, model)
          when View::ModelMapping::TYPE_METHOD
            if :default == mapping.in_method
              map_view_properties_to_model(mapping, model)
            else
              instance_eval("model.#{mapping.model_property.to_s} = method(mapping.out_method).call(model)")
            end
          when View::ModelMapping::TYPE_RAW
            method(mapping.out_method).call(model)
          end
        end
      end
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
      field_name = field_name.to_sym
      if @@is_a_java_class
        field_object = get_field(field_name)
        Java.java_to_ruby(field_object.value(Java.ruby_to_java(@main_view_component)))
      else
        get_field(field_name).call
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
          [field_name.to_s, field_name.camelize, field_name.camelize(false)].uniq.each do |name|
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
    
    # Raises exceptions for any invalid mapping combinations (nil parameters, mistyped method
    # names, etc.).  Also sets a direction and type for faster processing.
    def validate_mappings
      @__valid_mappings = self.class.view_mappings.map do |mapping|
        mapping = mapping.dup
        if mapping.properties_only?
          if mapping.both_properties_present?
            mapping.direction = View::ModelMapping::DIRECTION_BOTH
            mapping.type = View::ModelMapping::TYPE_PROPERTIES
          else
            raise InvalidMappingError, "Only one property declared with map in #{self.class}"
          end
        elsif mapping.both_properties_and_methods?
          mapping.type = View::ModelMapping::TYPE_METHOD
          if mapping.both_methods_present?
            mapping.direction = View::ModelMapping::DIRECTION_BOTH
            validate_method(:both, mapping)
          else
            if mapping.in_method_present?
              mapping.direction = View::ModelMapping::DIRECTION_IN
              validate_method(:in, mapping)
            else
              mapping.direction = View::ModelMapping::DIRECTION_OUT
              validate_method(:out, mapping)
            end
          end
        elsif mapping.methods_only?
          mapping.type = View::ModelMapping::TYPE_RAW
          if mapping.both_methods_present?
            mapping.direction = View::ModelMapping::DIRECTION_BOTH
          elsif mapping.in_method_present?
            mapping.direction = View::ModelMapping::DIRECTION_IN
          else
            mapping.direction = View::ModelMapping::DIRECTION_OUT
          end
        else
          raise InvalidMappingError, "Invalid mapping in #{self.class}, invalid map() or raw_mapping() arguments"
        end
        mapping
      end
    end
    
    def validate_method(direction, mapping)
      if :both == direction
        directions = [:in, :out]
      else
        directions = [direction]
      end
      directions.each do |direction|
        next if :default == mapping.send("#{direction}_method")
        raise InvalidMappingError, "Invalid '#{direction}' method: #{mapping.send("#{direction}_method")} declared in #{self.class}" unless self.respond_to?(mapping.send("#{direction}_method"))
      end
    end
    
    def map_model_properties_to_view(mapping, model)
      begin
        instance_eval("self.#{mapping.view_property.to_s} = model.#{mapping.model_property.to_s}")
      rescue NoMethodError
        raise InvalidMappingError, "Either model.#{mapping.model_property.to_s} or self.#{mapping.view_property.to_s} in #{self.class} is not valid."
      rescue TypeError => e
        raise InvalidMappingError, "Invalid types when assigning from model.#{mapping.model_property.to_s} to self.#{mapping.view_property.to_s}, #{e.message} in #{self.class}"
      end
    end
    
    def map_view_properties_to_model(mapping, model)
      begin
        instance_eval("model.#{mapping.model_property.to_s} = self.#{mapping.view_property.to_s}")
      rescue NoMethodError
        raise InvalidMappingError, "Either model.#{mapping.model_property.to_s} or self.#{mapping.view_property.to_s} in #{self.class} is not valid."
      rescue TypeError => e
        raise InvalidMappingError, "Invalid types when assigning from self.#{mapping.view_property.to_s}, #{e.message} in #{self.class} to model.#{mapping.model_property.to_s}"
      end
    end
  end
end

Component = java.awt.Component
# The java.awt.Component class is opened and a new method is added to allow
# you to ignore certain events during a call to update_view.
class Component
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
      listener_class = Monkeybars::Handlers::AWT_TYPES.member?(type) ? eval("java.awt.event.#{type}Listener") : eval("javax.swing.event.#{type}Listener")
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

class UndefinedControlError < Exception; end
class InvalidMappingError < Exception; end

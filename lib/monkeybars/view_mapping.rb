require 'monkeybars/validated_hash'

module Monkeybars
  class InvalidMappingError < Exception; end

  # This is an internal class used only by Monkeybars::View
  #
  # A Mapping records the relationship between the fields of a model or
  # transfer hash and the fields of a view.  Mappings are created for each call 
  # to View.map.  During first usage, the mappings are inspected for validity 
  # and are assigned a type (one of the constants defined in Mapping) to speed
  # up processing.  Invalid mappings raise an exception.
  class Mapping #:nodoc:
    DIRECTION_TO_VIEW = :to_view
    DIRECTION_FROM_VIEW = :from_view
    DIRECTION_BOTH = :both
    MODEL = :model
    TRANSFER = :transfer

    class << self
      alias_method :__new__, :new
    end
    
    def self.new(mapping_options = {})
      mapping_options.validate_only(:view, :model, :transfer, :using, :ignoring)
      mapping_options.extend HashMappingValidation
      
      if mapping_options.properties_only?
        PropertyMapping.__new__(mapping_options)
      elsif mapping_options.methods_only?
        RawMapping.__new__(mapping_options)
      elsif mapping_options.both_properties_and_methods?
        MethodMapping.__new__(mapping_options)
      else
        raise InvalidMappingError, "Cannot determine mapping type with parameters #{mapping_options.inspect}"
      end
    end
    
    def initialize(mapping_options = {})
      @view_property = mapping_options[:view] || nil
      @model_property = mapping_options[:model] || nil
      @transfer_property = mapping_options[:transfer] || nil
      @to_view_method, @from_view_method = if mapping_options[:using]
        if mapping_options[:using].kind_of? Array
          [mapping_options[:using][0], mapping_options[:using][1]]
        else
          [mapping_options[:using], nil]
        end
      else
        [nil, nil]
      end

      @event_types_to_ignore = if mapping_options[:ignoring]
        if mapping_options[:ignoring].kind_of? Array
          mapping_options[:ignoring]
        else
          [mapping_options[:ignoring]]
        end
      else
        []
      end
      
      if mapping_options.both_model_and_transfer_present?
        raise InvalidMappingError, "Both model and transfer parameters were given"
      elsif mapping_options.at_least_one_property_present? and !mapping_options.both_properties_present?
        raise InvalidMappingError, "Both a view and a model/transfer property must be provided"
      end
      set_direction(mapping_options)
    end
    
    def maps_to_view?
      (DIRECTION_BOTH == @direction) or (DIRECTION_TO_VIEW == @direction)
    end
    
    def maps_from_view?
      (DIRECTION_BOTH == @direction) or (DIRECTION_FROM_VIEW == @direction)
    end
    
    def to_view(view, model, transfer)
      disable_declared_handlers(view) do
        if model_mapping?
          model_to_view(view, model)
        else
          transfer_to_view(view, transfer)
        end
      end
    end
    
    def from_view(view, model, transfer)
      disable_declared_handlers(view) do
        if model_mapping?
          model_from_view(view, model)
        elsif transfer_mapping?
          transfer_from_view(view, transfer)
        end
      end
    end

    def model_mapping?
      !@model_property.nil?
    end

    def transfer_mapping?
      !@transfer_property.nil?
    end

    private
    
    def set_direction(mapping_options)
      @direction = if mapping_options.both_methods_present?
        DIRECTION_BOTH
      elsif mapping_options.to_view_method_present?
        DIRECTION_TO_VIEW
      else
        DIRECTION_FROM_VIEW
      end
    end
    
    def disable_declared_handlers(view, &block)
      if @event_types_to_ignore.empty?
        yield
      else
        field = view.get_field_value(/^(\w+)\.?/.match(@view_property)[1])
        @event_types_to_ignore.each do |event_type|
          field.disable_handlers(event_type, &block)
        end
      end
    end
  end
  
  class BasicPropertyMapping < Mapping
    def model_to_view(view, model)
      begin
        instance_eval("view.#{@view_property} = model.#{@model_property}")
      rescue NoMethodError
        raise InvalidMappingError, "Either model.#{@model_property} or self.#{@view_property} in #{view.class} is not valid."
      rescue TypeError => e
        raise InvalidMappingError, "Invalid types when assigning from model.#{@model_property} to self.#{@view_property}, #{e.message} in #{view.class}"
      end
    end
    
    def transfer_to_view(view, transfer)
      begin
        instance_eval("view.#{@view_property} = transfer[#{@transfer_property.inspect}]")
      rescue NoMethodError
        raise InvalidMappingError, "Either transfer[#{@transfer_property}] or self.#{@view_property} in #{view.class} is not valid."
      rescue TypeError => e
        raise InvalidMappingError, "Invalid types when assigning from transfer[#{@transfer_property}] to self.#{@view_property}, #{e.message} in #{view.class}"
      end
    end
    
    def model_from_view(view, model)
      begin
        instance_eval("model.#{@model_property} = view.#{@view_property}")
      rescue NoMethodError
        raise InvalidMappingError, "Either model.#{@model_property} or self.#{@view_property} in #{view.class} is not valid."
      rescue TypeError => e
        raise InvalidMappingError, "Invalid types when assigning from model.#{@model_property} to self.#{@view_property}, #{e.message} in #{view.class}"
      end
    end
    
    def transfer_from_view(view, transfer)
      begin
        instance_eval("transfer[#{@transfer_property.inspect}] = view.#{@view_property}")
      rescue NoMethodError
        raise InvalidMappingError, "Either transfer[#{@transfer_property}] or self.#{@view_property} in #{view.class} is not valid."
      rescue TypeError => e
        raise InvalidMappingError, "Invalid types when assigning from transfer[#{@transfer_property}] to self.#{@view_property}, #{e.message} in #{view.class}"
      end
    end
    
    private
    def self.new(*args)
      raise "#{self} is not a concrete class"
    end
  end
  
  class RawMapping < Mapping
    def to_view(view, model, transfer)
      disable_declared_handlers(view) do
        view.method(@to_view_method).call(model, transfer)
      end
    end
    
    def from_view(view, model, transfer)
      view.method(@from_view_method).call(model, transfer) unless @from_view_method.nil?
    end
  end
  
  class PropertyMapping < BasicPropertyMapping
    def set_direction(mapping_options)
      @direction = DIRECTION_BOTH
    end
  end

  class MethodMapping < BasicPropertyMapping
    def model_to_view(view, model)
      if :default == @to_view_method
        super
      else
        instance_eval("view.#{@view_property} = view.method(@to_view_method).call(model)")
      end
    end
    
    def transfer_to_view(view, transfer)
       if :default == @to_view_method
        super
      else
        instance_eval("view.#{@view_property} = view.method(@to_view_method).call(transfer)")
      end
    end
    
    def model_from_view(view, model)
      if :default == @from_view_method
        super
      else
        instance_eval("model.#{@model_property} = view.method(@from_view_method).call(model)")
      end
    end
    
    def transfer_from_view(view, transfer)
      if :default == @from_view_method
        super
      else
        instance_eval("transfer[#{@transfer_property.inspect}] = view.method(@from_view_method).call(transfer)")
      end
    end
  end
  
  module HashMappingValidation
    def properties_only?
      (at_least_one_property_present? and !at_least_one_method_present?) ? true : false
    end

    def both_properties_and_methods?
      (both_properties_present? and at_least_one_method_present?) ? true : false
    end

    def methods_only?
      (!at_least_one_property_present? and at_least_one_method_present?) ? true : false
    end

    def both_properties_present?
      !self[:view].nil? and (!self[:model].nil? or !self[:transfer].nil?)
    end

    def both_model_and_transfer_present?
      !self[:model].nil? and !self[:transfer].nil?
    end
    
    def both_methods_present?
      !to_view_method.nil? and !from_view_method.nil?
    end

    def to_view_method_present?
      !to_view_method.nil?
    end

    def from_view_method_present?
      !from_view_method.nil?
    end

    def at_least_one_property_present?
      !self[:view].nil? or !self[:model].nil? or !self[:transfer].nil?
    end

    def at_least_one_method_present?
      !to_view_method.nil? or !from_view_method.nil?
    end
    
    def to_view_method
      if self[:using].kind_of? Array
        self[:using].first
      else
        self[:using]
      end
    end
    
    def from_view_method
      if self[:using].kind_of? Array
        self[:using][1]
      else
        nil
      end
    end
  end
end
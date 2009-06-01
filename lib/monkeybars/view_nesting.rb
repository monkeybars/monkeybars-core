module Monkeybars  
  class Nesting
    class << self
      alias_method :__new__, :new
    end
    
    def self.new(nesting_options = {})
      nesting_options.validate_only(:sub_view, :using, :view)
      nesting_options.extend Monkeybars::HashNestingValidation

      if nesting_options.property_only?
        PropertyNesting.__new__(nesting_options)
      elsif nesting_options.methods_only?
        MethodNesting.__new__(nesting_options)
      else
        raise InvalidNestingError, "Cannot determine nesting type with parameters #{nesting_options.inspect}"
      end
    end
    
    def initialize(properties)
      @sub_view = properties[:sub_view]
    end
  end
  
  class PropertyNesting < Nesting
    def initialize(properties)
      super
      @view_property = properties[:view]
    end
    
    def nests_with_add?
      true
    end
    
    def nests_with_remove?
      true
    end
    
    def add(view, nested_view, nested_component, model, transfer)
      instance_eval("view.#{@view_property}.add nested_component")
    end
    
    def remove(view, nested_view, nested_component, model, transfer)
      instance_eval("view.#{@view_property}.remove nested_component")
    end
  end
  
  class MethodNesting < Nesting
    def initialize(nesting_options)
      super
      @add_method, @remove_method = if nesting_options[:using].kind_of? Array
        [nesting_options[:using][0], nesting_options[:using][1]]
      else
        [nesting_options[:using], nil]
      end
    end

    def to_s
      ":sub_view => #{@sub_view.inspect}, :using => [#{@add_method.inspect}, #{@remove_method.inspect}]"
    end
    
    def nests_with_add?
      !@add_method.nil?
    end
    
    def nests_with_remove?
      !@remove_method.nil?
    end
    
    def add(view, nested_view, nested_component, model, transfer)
      #instance_eval("view.#{@add_method}(@sub_view, model, transfer)")
      raise NameError.new "Add method not provided for nesting #{self}" if @add_method.nil? || !view.respond_to?(@add_method)
      view.send(@add_method, nested_view, nested_component, model, transfer)
    end
    
    def remove(view, nested_view, nested_component, model, transfer)
      #instance_eval("view.#{@remove_method}(@sub_view, model, transfer)")
      raise NameError.new "Remove method not provided for nesting #{self}" if @remove_method.nil? || !view.respond_to?(@remove_method)
      view.send(@remove_method, nested_view, nested_component, model, transfer)
    end
  end
  
  module HashNestingValidation
    def property_only?
      property_present? and not (to_view_method_present? and from_view_method_present?)
    end
    
    def methods_only?
      (to_view_method_present? or from_view_method_present?) and not property_present?
    end
    
    def property_present?
      !self[:view].nil?
    end
    
    def to_view_method_present?
      !to_view_method.nil?
    end

    def from_view_method_present?
      !from_view_method.nil?
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
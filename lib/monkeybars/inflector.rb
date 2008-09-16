# This code is a modified version of the Inflector class
# from the Ruby on Rails project (http://www.rubyonrails.com)

module Monkeybars
  module Inflector
    # The reverse of +camelize+. Makes an underscored form from the expression in the string.
    #
    # Changes '::' to '/' to convert namespaces to paths.
    #
    # Examples
    #   "ActiveRecord".underscore #=> "active_record"
    #   "ActiveRecord::Errors".underscore #=> active_record/errors
    def underscore()
      self.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    # Constantize tries to find a declared constant with the name specified
    # in the string. It raises a NameError when the name is not in CamelCase
    # or is not initialized.
    #
    # Examples
    #   "Module".constantize #=> Module
    #   "Class".constantize #=> Class
    def constantize()
      unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ self.to_s
        raise NameError, "#{self.inspect} is not a valid constant name!"
      end

      Object.module_eval("::#{$1}", __FILE__, __LINE__)
    end

    # By default, camelize converts strings to UpperCamelCase. If the argument to camelize
    # is set to ":lower" then camelize produces lowerCamelCase.
    #
    # camelize will also convert '/' to '::' which is useful for converting paths to namespaces
    #
    # Examples
    #   "active_record".camelize #=> "ActiveRecord"
    #   "active_record".camelize(:lower) #=> "activeRecord"
    #   "active_record/errors".camelize #=> "ActiveRecord::Errors"
    #   "active_record/errors".camelize(:lower) #=> "activeRecord::Errors"
    def camelize(first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        self.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      else
        self.to_s[0..0] + camelize(self.to_s)[1..-1]
      end
    end
  end
end

class String
  include Monkeybars::Inflector
end

class Symbol
  include Monkeybars::Inflector
end

class Class
  def constantize
    self
  end
end
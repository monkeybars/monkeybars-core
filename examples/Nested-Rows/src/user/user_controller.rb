class UserController < ApplicationController
  set_model 'UserModel'
  set_view 'UserView'
  set_close_action :close
  
  def load(first_name, last_name, age)
    model.first_name = first_name
    model.last_name = last_name
    model.age = age
  end
  
  #just chain the call along to the model with the other model
  def <=>(other)
    model <=> other.send(:model)
  end
  
  def set_sort_by_field(field)
    model.sort_by_field = field
  end
end

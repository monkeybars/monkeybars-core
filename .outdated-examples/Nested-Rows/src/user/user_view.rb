class UserView < ApplicationView
  set_java_class 'user.UserPanel'
  
  map :view => 'first_name_text_field.text', :model => :first_name
  map :view => 'last_name_text_field.text', :model => :last_name
  map :view => 'age_text_field.text', :model => :age, :using => [:to_s, :to_i]
  
  def to_s(fixnum)
    fixnum.to_s
  end
  
  def to_i(string)
    string.to_i
  end
end

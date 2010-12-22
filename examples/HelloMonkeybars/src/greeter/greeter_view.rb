class GreeterView < ApplicationView
  set_java_class 'Hello'
  
  map :view => "message.text", :model => :message
end

class GreeterController < ApplicationController
  set_model 'GreeterModel'
  set_view 'GreeterView'
  set_close_action :exit

  def improve_button_action_performed
    model.message = "<html>But Swing with Monkeybars<br>is awesome!</html>"
    update_view
  end
end
#
# We use a trick to display a modal dialog with owner frame. We get the top frame
# via @@top_frame defined in the application_view.rb


class ChooserDialogController < ApplicationController
  set_model 'ChooserDialogModel'
  set_view 'ChooserDialogView'
  set_close_action :exit
  
  
  def load()
  end

  def selected_file=(filename)
    model.selected_file = filename
  end

  def display
    transfer[:selected_file] = model.selected_file
    signal :popup_dialog
    update_view
  end

  def filechooser_action_performed(event)
    signal :close_dialog
    return if 'CancelSelection' == event.action_command
    filename = event.source.selected_file.to_s
    model.selected_file = filename
puts event
    @after_choose_callback.call(filename)
  end

  def after_choose(&block)
    @after_choose_callback = block
  end
end

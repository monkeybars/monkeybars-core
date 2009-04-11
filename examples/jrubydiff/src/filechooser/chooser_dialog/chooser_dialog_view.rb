class ChooserDialogView < ApplicationView
  set_java_class 'filechooser.chooser_dialog.FilechooserPanel'

  map :model => :start_dir, :view => 'filechooser.current_directory'

  attr_accessor :dialog

  def load
    @dialog = Java::javax.swing.JDialog.new(@@top_frame, false)
    @dialog.add(@main_view_component)
    @dialog.pack

    center @dialog # move filechooser dialog to the screen center
  end

  define_signal :name => :close_dialog, :handler => :close_dialog
  define_signal :name => :popup_dialog, :handler => :popup_dialog

  def close_dialog(model, transfer)
    @dialog.hide
    @dialog.modal = false
  end

  def popup_dialog(model, transfer)
    @dialog.modal = true
    model.selected_file = transfer[:selected_file]
puts    filechooser.current_directory = model.start_dir
    @dialog.show
  end

end

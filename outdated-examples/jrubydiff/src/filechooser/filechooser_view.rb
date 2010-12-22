include_class 'filechooser.ChooseFilePanel'
class FilechooserView < ApplicationView
  set_java_class 'filechooser.ChooseFilePanel'

  attr_accessor :top_main_frame, :@view_main_component

  map :view => 'filename_text_field.text', :model => :filename

  define_signal :name => :restore_filename, :handler => :restore_filename

  def restore_filename(model, transfer)
    filename_text_field.text = model.filename
  end

end

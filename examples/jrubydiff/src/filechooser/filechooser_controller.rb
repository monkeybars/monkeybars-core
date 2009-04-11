require 'chooser_dialog_controller'

class FilechooserController < ApplicationController
  set_model 'FilechooserModel'
  set_view 'FilechooserView'
  set_close_action :exit

  attr_accessor :chooser_dialog, :file_changed_callback

  def load
    @chooser_dialog = ChooserDialogController.create_instance
    @chooser_dialog.after_choose do |filename|
      filechoosed(filename)
    end
  end

  def clear
    model.filename = nil
    update_view
  end

  def selected_file=(filename)
    model.filename = filename
    update_view
    @chooser_dialog.selected_file = filename
  end


  def choose_file_button_action_performed
    @chooser_dialog.open
    @chooser_dialog.display
  end

  def filename_text_field_action_performed(event)
    filename_changed(event)
  end

  
  def filename_changed(event)
    filename = event.source.text
    filechoosed(filename) if filename.length > 0
  end
  
  def when_file_changed(&block)
    @file_changed_callback = block
  end

  def filechoosed(filename)
    # we check file exists or not first, coz use may make a typo error when editting the filename textfield
    puts "[#{filename}]"
    if filename
      begin
        File.new(filename, 'r')
      rescue Exception => e
        show_msg('File not exists', e.to_s)
        signal :restore_filename
        return
      end
    end
    unless filename == model.filename
      model.filename = filename
      @chooser_dialog.selected_file = filename
      @file_changed_callback.call filename
      update_view
    end
  end
end

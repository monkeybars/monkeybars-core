require 'filechooser_controller'
require 'diff_panel_controller'

class DiffController < ApplicationController
  set_model 'DiffModel'
  set_view 'DiffView'
  set_close_action :close

  def load
    # add filechooser to the main frame
    @filechooser_controller_a = FilechooserController.create_instance
    @filechooser_controller_b = FilechooserController.create_instance

    add_nested_controller(:filechooser_a, @filechooser_controller_a)
    add_nested_controller(:filechooser_b, @filechooser_controller_b)

    @filechooser_controller_a.open
    @filechooser_controller_b.open
    
    @filechooser_controller_a.when_file_changed do |filename|
      model.filename_a = filename
      show_diff if model.filename_a && model.filename_b
      update_view
    end
    @filechooser_controller_b.when_file_changed do |filename|
      model.filename_b = filename
      show_diff if model.filename_a && model.filename_b
      update_view
    end

    # add diff_panel to the main frame
    @diff_panel_a = DiffPanelController.create_instance
    add_nested_controller(:diff_panel_a, @diff_panel_a)
    @diff_panel_a.open({:title => model.title_a, :content => model.content_a})
    @diff_panel_b = DiffPanelController.create_instance
    add_nested_controller(:diff_panel_b, @diff_panel_b)
    @diff_panel_b.open({:title => model.title_b, :content => model.content_b})

    @diff_panel_a.sync(@diff_panel_b)
  end

  # We register current frame as the top frame which defined in application_view.rb.
  # But you don't have access to the top frame in DiffController class.
  # So we use a signal to ask DiffView class do the registeration work instead.
  # You can access the top frame via @main_view_component in DiffView class.
  def java_window_window_gained_focus(event)
    # Can't get this to work on my mac for some reason -- Java 1.6 vs Java 1.5?
    #signal :register_main_frame
  end
  
  # main frame lost focus.
  # If you want to do some process when main frame lost focus, add your code here.
  def java_window_window_lost_focus(event)
    #puts 'main_frame lost focus'
  end

  def java_window_component_resized(event)
    signal :center_split_bar
  end

  # exchange the selected files and show diff
  def exchange_button_action_performed(view_state)
    model.filename_a, model.filename_b = model.filename_b, model.filename_a
    @filechooser_controller_a.selected_file = model.filename_a
    @filechooser_controller_b.selected_file = model.filename_b
    show_diff
  end

  # display the diff between the two selected files.
  def show_diff
    # check file exists or not
    filenames = [model.filename_a, model.filename_b]
    begin
      # check file exists or not.
      filenames.each { |f| File.new(f, 'r') }

      repaint_while {
        model.diff
        @diff_panel_a.set_content({:title => model.title_a, :content => model.content_a})
        @diff_panel_b.set_content({:title => model.title_b, :content => model.content_b})
      }
    rescue Exception => e
      show_msg('File not exists', e.to_s)
    end

  end

  # menu item actions
  def menu_item_new_window_action_performed(event)
    DiffController.create_instance.open
  end
  def menu_item_exit_action_performed(event)
    signal :close_window
  end
  def menu_item_clear_both_action_performed(event)
    puts 'clear'
    model.clear
    @diff_panel_a.set_content({:title => 'file 1', :content => model.content_a})
    @diff_panel_b.set_content({:title => 'file 2', :content => model.content_b})
    @filechooser_controller_a.clear
    @filechooser_controller_b.clear
    update_view
  end
  def menu_item_about_action_performed(event)
    about = Java::diff.AboutBox.new(nil, true)
    transfer[:window] = about
    signal :center_window
    about.show
  end
  
  # splite_panel resize event
  def split_panel_property_change(event)
    #puts 'splite_panel propertye_change'+event.to_s
  end

end

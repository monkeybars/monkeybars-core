class DiffView < ApplicationView
  set_java_class 'diff.DiffFrame'

  map :view => 'exchange_button.enabled', :model => :exchange_button_enabled

  nest :sub_view => :filechooser_a, :view => :filechooser_panel1
  nest :sub_view => :filechooser_b, :view => :filechooser_panel2

  nest :sub_view => :diff_panel_a, :view => :diff_panel_placeholder_a
  nest :sub_view => :diff_panel_b, :view => :diff_panel_placeholder_b

  define_signal :name => :register_main_frame, :handler => :register_main_frame
  define_signal :name => :center_split_bar, :handler => :center_split_bar
  define_signal :name => :close_window, :handler => :close_window

  define_signal :name => :center_window, :handler => :center_window

  def center_window(model, transfer)
    window = transfer[:window]
    center window
  end
  
  def center_split_bar(model, transfer)
    center_split_panel
  end

  def close_window(model, transfer)
    @main_view_component.dispose
  end
  
  def register_main_frame(model, transfer)
    @@top_frame = @main_view_component
  end
  
  def load
    @@top_frame = @main_view_component
    center_split_panel
    center
  end

  def add_filechooser1(view, component, model, transfer)
    view.parent_component = [@main_view_component, filechooser_panel1]
    filechooser_panel1.validate
  end
  def add_filechooser2(view, component, model, transfer)
    view.parent_component = [@main_view_component, filechooser_panel2]
    filechooser_panel2.validate
  end

  def center_split_panel
    split_panel.divider_location = 0.5000
  end
end

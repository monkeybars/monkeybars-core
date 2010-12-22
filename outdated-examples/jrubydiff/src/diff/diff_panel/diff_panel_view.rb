class DiffPanelView < ApplicationView
  set_java_class 'diff.diff_panel.DiffPanel'

  map :view => 'title.text', :model => :title

  define_signal :name => :sync, :handler => :sync
  define_signal :name => :add_content, :handler => :add_content
  define_signal :name => :get_scroll_panel, :handler => :get_scroll_panel

  
  def load
     
  end

  def add_content(model, transfer)
    contents = model.content
    diff_panel.clear

    begin
      contents.compact.each do |line|
        continue if line.size < 2
        text = line[0].to_s
        style = line[1].to_s

        diff_panel.insert_string(text, style)
      end
    rescue Exception => e
      puts e
    end
  end

  def sync(model, transfer)
    other_scroll_panel = transfer[:scroll_panel]
    scroll_panel.vertical_scroll_bar.model = other_scroll_panel.vertical_scroll_bar.model
    other_scroll_panel.get_vertical_scroll_bar.model = scroll_panel.vertical_scroll_bar.model
  end

  def get_scroll_panel(model, transfer)
    transfer[:scroll_panel] = scroll_panel
  end
end

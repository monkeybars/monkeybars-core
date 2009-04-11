class DiffPanelController < ApplicationController
  set_model 'DiffPanelModel'
  set_view 'DiffPanelView'
  set_close_action :exit

  def load(content)
    set_content content
  end

  def set_content(content)
    model.title = content[:title]
    model.content = content[:content]
    signal :add_content
    update_view
  end

  def get_scroll_panel
    puts @__view.class.signal_mappings.inspect
    signal :get_scroll_panel
    transfer[:scroll_panel]
  end

  # syc the two diff panel, so we can scroll the two panel at the same time.
  def sync(diff_panel_controller)
    transfer[:scroll_panel] = diff_panel_controller.get_scroll_panel
    signal :sync
  end

end

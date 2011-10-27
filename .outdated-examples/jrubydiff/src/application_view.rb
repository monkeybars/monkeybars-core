class ApplicationView < Monkeybars::View
  # We use class variable @@top_frame point to the current frame.
  # So we can popup a JDialog with owner frame.
  @@top_frame = nil

  # center the top frame or dialog.
  def center(frame = nil)
    frame ||= @main_view_component
    tk = Java::java.awt.Toolkit.default_toolkit
    #tk.beep()

    screen = tk.screen_size
    size = frame.size
    width = size.width
    height = size.height
    x = (screen.width - width)/2
    y = (screen.height - height)/2
    frame.location = Java::java.awt.Point.new x,y
  end

end
class ChooserDialogModel
  attr_reader :selected_file, :start_dir

  def initialize
    self.selected_file=(__FILE__)
  end

  def selected_file=(filename)
    @selected_file = filename
    @start_dir = Java::java.io.File.new File.expand_path(File.dirname(@selected_file))
  end
end

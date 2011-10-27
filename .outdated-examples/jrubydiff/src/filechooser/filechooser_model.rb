class FilechooserModel
  attr_accessor :filename

  def load
    @filename = nil
    @selected_file = nil
  end
end

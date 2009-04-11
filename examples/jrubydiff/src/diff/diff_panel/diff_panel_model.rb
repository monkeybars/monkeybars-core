class DiffPanelModel
  attr_accessor :title, :content, :background

  def load(content)
    @title = content[:title]
    @content = content[:content]
    @content_type = 'text/html'
    @background = Java::java.awt.Color.new(255, 255, 255)
  end
end

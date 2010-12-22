require 'text_diff'

class DiffModel
  attr_accessor :filename_a, :filename_b, :title_a, :title_b, :content_a, :content_b, :exchange_button_enabled

  def initialize
    clear
    @exchange_button_enabled = false
  end

  def clear
    @filename_a = nil
    @filename_b = nil
    @content_a = []
    @content_b = []
    @title_a   = 'file 1'
    @title_b   = 'file 2'
    @exchange_button_enabled = false
  end

  def diff
    a = '', b = ''
    begin
      a = File.new(@filename_a).read.split(/\r?\n|\n/) # use split(/\r?\n|\n/) to split the file content. because we don't know the file's
      b = File.new(@filename_b).read.split(/\r?\n|\n/)
      # add \n to the line end
      a = a.map { |line| line+"\n" }
      b = b.map { |line| line+"\n" }
    rescue
      return false
    end
    #a = a.join("\n"), b = b.join("\n") # if you want to compare byte by byte, remove comment of the line
    require 'diff/lcs'
    @content_a = []
    @content_b = []

    td = TextDiff.new(@content_a, @content_b)
    Diff::LCS.traverse_sequences(a, b, td)
    
    td.check_finished
  end


  def add_styled_content(content_array, content, style)
    content_array << [content, style ? style : @same_style ]
  end

  def filename_a=(filename)
    @title_a = File.basename(filename)
    @filename_a = filename if filename && filename.size > 0
    check_compare_button_status
  end
  def filename_b=(filename)
    @title_b = File.basename(filename)
    @filename_b = filename if filename && filename.size > 0
    check_compare_button_status
  end

  def check_compare_button_status
    @exchange_button_enabled = (@filename_a != nil && @filename_b != nil)
    @exchange_button_enabled
  end
end

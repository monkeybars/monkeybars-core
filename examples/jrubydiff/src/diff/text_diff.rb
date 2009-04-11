class TextDiff
  attr_accessor :content_a, :content_b

  def initialize(content_a, content_b)
    @content_a = content_a
    @content_b = content_b
    @pos_a = -1
    @pos_b = -1
    @finished_a = false
    @finished_b = false
    @extra_a = []
    @extra_b = []
    @pre_action = nil
  end

  def add_blank_line(seq, pos)
    @extra_a << pos if seq == :a && pos >= 0
    @extra_b << pos if seq == :b && pos >= 0
  end

  
	# This will be called with both lines are the same
  def match(event)
    #puts "#{event.to_a.inspect} match size_a => #{size_a}, size_b => #{size_b}"
    # make sure the two diff content display the same content on the same line.
    size_a = @extra_a.size + @content_a.size
    size_b = @extra_b.size + @content_b.size
    
    add_blank_line(:a, event.old_position) if size_a < size_b
    add_blank_line(:b, event.new_position) if size_b < size_a

    @content_a << [event.old_element, :same]
    @content_b << [event.old_element, :same]
    @pre_action = :same
  end

	# This will be called when there is a line in A that isn't in B
  def discard_a(event)
    #puts event.to_a.inspect.to_s+'discard_a'
    pos = event.new_position
    add_blank_line(:b, pos) if 0 == pos || @finished_b
    @pos_b = pos

  	@content_a << [event.old_element, :diff]
    @pos_a = event.old_position

    if @pre_action == :- && @pos_b > 0 && !@finished_b
      @pos_b = event.new_position
      add_blank_line :b, @pos_b+1
    end
    @pre_action = :-
  end

	# This will be called when there is a line in B that isn't in A
  def discard_b(event)
    #puts event.to_a.inspect.to_s+'discard_b'
    old_pos = event.old_position
    add_blank_line(:a, old_pos) if 0 == old_pos || @finished_a

    pos = event.new_position

    style = old_pos == 0 || @finished_a ? :add : :diff
  	@content_b << [event.new_element, style]
    @pos_b = pos
    @pos_a = event.old_position
    if @pre_action==:+ && old_pos > 0 && !@finished_a
      add_blank_line :a, @pos_a
      @add_a=false
      #puts "     :+ add_a_pos => #{@add_a_pos}, add_a => #{@add_a}, pos_a => #{@pos_a}"
    end

    @pre_action = :+

  end

  def finished_a(event)
    @finished_a = true
  end
  def finished_b(event)
    @finished_b = true
  end
  def check_finished
    i = 0
    #puts 'finished a => '+@extra_a.inspect.to_s+', b => '+@extra_b.inspect.to_s
    @extra_a.reverse.each do |pos|
      i += 1
      @content_a.insert(pos, ["++++++\n", :same]) if pos > -1
    end
    i = 0
    @extra_b.reverse.each do |pos|
      i += 1
      @content_b.insert(pos, ["++++++\n", :same]) if pos > -1
    end

  end
end
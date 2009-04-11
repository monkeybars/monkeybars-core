# To change this template, choose Tools | Templates
# and open the template in the editor.

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << File.expand_path(File.dirname(__FILE__)+'/../src/diff')
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))+'/../lib/ruby'

require 'diff/lcs'

seq1 = File.new('demo1.txt').read.split(/\r?\n|\n/)
seq2 = File.new('demo2.txt').read.split(/\r?\n|\n/)

#seq1 = %w(a b c e h j l m n p)
#seq2 = %w(b c d e f j k l m r s t)

content_a = []
content_b = []
class TextDiff #:nodoc:
  attr_accessor :content_a, :content_b

  def initialize(content_a, content_b)
	@content_a = content_a
	@content_b = content_b
	@pos_a = 0
	@pos_b = 0
  end

	# This will be called with both lines are the same
  def match(event)
	@content_a << [%Q|#{event.to_a.inspect}#{event.old_element}\n|, :same]
	@content_b << [%Q|#{event.to_a.inspect}#{event.old_element}\n|, :same]
  end

	# This will be called when there is a line in A that isn't in B
  def discard_a(event)
	@content_a << [%Q|#{event.to_a.inspect}#{event.old_element}\n|, :diff]
	@content_b << ["\n", :same] if @pos_b = event.new_position
	@pos_b = event.new_position
  end

	# This will be called when there is a line in B that isn't in A
  def discard_b(event)
	@content_b << [%Q|#{event.to_a.inspect}#{event.new_element}\n|, :add]
	@content_a << ["\n", :same] if @pos_a == event.old_position
	@pos_a = event.old_position
  end
end
hd = TextDiff.new(content_a, content_b)
diffs = Diff::LCS.traverse_sequences(seq1, seq2, hd)
puts hd.content_a, '--------', hd.content_b

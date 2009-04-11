module Monkeybars
  module Swing

    # A button wrapper
    # See http://xxxxxxxx to understand Swing buttons
    class Button < Java::javax::swing::JButton
      def initialize
        super
        yield self if block_given?
      end
    end


    class MenuBar < Java::javax.swing.JMenuBar
      def initialize
        super
        yield self if block_given?
      end

    end



    class MenuItem  < Java::javax.swing.JMenuItem
      def initialize
        super
        yield self if block_given?
      end
    end


    class Menu  < Java::javax.swing.JMenu
      def initialize
        super
        yield self if block_given?
      end
    end


    # A label  wrapper
    # See http://xxxxxxxx to understand Swing labels
    class Label < Java::javax::swing::JLabel
      def initialize(text=nil)
        super
        self.text = text.to_s
        yield self if block_given?
      end

      def minimum_dimensions(w,h)
        self.minimum_size = java::awt::Dimension.new(w, h)
      end

      def prefered_dimensions(w,h)
        self.prefered_size = java::awt::Dimension.new(w, h)
      end
    end


    # A panel  wrapper
    # See http://xxxxxxxx to understand Swing panels
    class Panel < javax::swing.JPanel

      def background_color(red, blue, green)
        self.background = java::awt::Color.new(red.to_i, blue.to_i, green.to_i)
      end

      def size(height, width)
        self.preferred_size =  java::awt::Dimension.new(width, height)
      end
    end


    # A frame  wrapper
    # See http://xxxxxxxx to understand Swing frames
    class Frame  < Java::javax::swing::JFrame
      attr_accessor :minimum_height, :minimum_width

      def initialize(*args)
        super
      end

      def define_minimum_size(height, width)
        self.minimum_size = java::awt::Dimension.new(height, width)
      end

      def minimum_height=(h)
        @minimum_height = h.to_i
        define_minimum_size @minimum_width.to_i, @minimum_height
      end

      def minimum_width=(w)
        @minimum_width = w.to_i
        define_minimum_size @minimum_width, @minimum_height.to_i
      end
    end
  end
end


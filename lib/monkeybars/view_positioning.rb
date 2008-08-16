module Monkeybars
  class View
    module Positioning

      include_class Java::java::awt::Toolkit

      # Returns a java.awt.Dimension
      def screen_size 
        Toolkit.default_toolkit.screen_size
      end

      def move_to(x, y)
        @main_view_component.set_location(x,y)
      end

      def move_to_center
        x = (screen_size.width - @main_view_component.width)/2
        y = (screen_size.height - @main_view_component.height)/2 
        move_to(x, y)
      end

      def move_to_top_right
        move_to(right_edge_x_coordinate, 0)
      end


      def move_to_top_left
        move_to(0, 0)
      end

      def move_to_bottom_left
        move_to(0, bottom_edge_y_coordinate)
      end

      def move_to_bottom_right
        screen_size = Toolkit.default_toolkit.screen_size
        move_to(right_edge_x_coordinate, bottom_edge_y_coordinate)
      end

      def x
        @main_view_component.location.x
      end

      def y
        @main_view_component.location.y
      end

      def width
	@main_view_component.width
      end
      
      def height
	@main_view_component.height
      end
      
    private
      def right_edge_x_coordinate
        screen_size.width - @main_view_component.width
      end

      def bottom_edge_y_coordinate
        screen_size.height - @main_view_component.height
      end
    end
  end
end

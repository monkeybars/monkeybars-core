module Monkeybars
  class View
    module Positioning

      include_class Java::java.awt.Toolkit

      def screen_size 
        Toolkit.default_toolkit.screen_size
      end

      def move_to(x,y)
        @main_view_component.set_location(x,y)
      end

      def right_x
        screen_size.width -  @main_view_component.width
      end

      def bottom_y
        screen_size.height - @main_view_component.height
      end

      def top_y
        0
      end

      def left_x
        0
      end

      def move_to_center
        x = (screen_size.width - @main_view_component.width)/2
        y = (screen_size.height - @main_view_component.height)/2 
        move_to(x,y)
      end

      def move_to_top_right
        move_to(right_x,top_y)
      end


      def move_to_top_left
        move_to(left_x,top_y)
      end

      def move_to_bottom_left
        move_to(left_x,bottom_y)
      end

      def move_to_bottom_right
        screen_size = Toolkit.default_toolkit.screen_size
        move_to(right_x, bottom_y)
      end

      def x
        @main_view_component.location.x
      end

      def y
        @main_view_component.location.y
      end

      def bounds_width
        @main_view_component.bounds.width
      end

      def bounds_height
        @main_view_component.bounds.height
      end

    end
  end
end

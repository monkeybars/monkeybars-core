# Monkeybars shouldn't force RSpec. Consider conditional RSpec require/include
require 'spec'
require 'monkeybars/inflector'
require 'monkeybars/task_processor'

module Monkeybars
  module Performer
    class User
      include Monkeybars::TaskProcessor
      include Spec::Matchers
      
      def initialize(controller_context)
        @controller_context = controller_context
      end

      #TODO: Events should execute in a seperate thread, such that blocking calls won't block the tests. Maybe an option?
      def clicks(component_name)
        view = @controller_context.instance_variable_get :@__view
        on_edt do
          view.send(component_name).do_click
        end
        sleep 1
      end

      def cannot_see(args)
        if args[:window]
          window_name = args[:window]
          window = get_window window_name
          window.should_not be_visible
        end
        sleep 1
      end

      def sees(args)
        view = @controller_context.instance_variable_get :@__view
        if !(args[:in].nil? || args[:value].nil?)
          view.instance_eval(args[:in]).should == args[:value]
        elsif !args[:window].nil?
          window_name = args[:window]
          window = get_window window_name
          window.should be_visible #unless args[:visibility_override]
        elsif !args[:panel].nil?
          panel_name = args[:panel]
          panel = get_window panel_name
          panel.should be_visible
        elsif !args[:table].nil?
          row = args[:row].to_i
          column = args[:column].to_i
          view = @controller_context.instance_variable_get :@__view
          table_component = view.send args[:table].gsub(' ','_')
          table_component.getModel.getValueAt(row, column).to_s.should == args[:data]
        end
        sleep 1
      end

      def closes(arg)
        if arg == :window
          @controller_context.close 
        else
          get_controller(arg[:window]).close
        end
        sleep 1
      end

      def exits
        Monkeybars::Controller.active_controllers.each {|name, controller| controller[0].close unless controller[0].nil? }
      end

      def selects(options)
        if options.key? :table
          row = options[:row].to_i
          column = options[:column].to_i
          view = @controller_context.instance_variable_get :@__view
          component = view.send options[:table].gsub(' ', '_')
          component.change_selection(row.to_i, column.to_i, false, false)
        elsif options.key? :tabbed_pane
          tab_name = options[:tab_name]
          view = @controller_context.instance_variable_get :@__view
          component = view.send options[:tabbed_pane]
          0.upto(component.get_tab_count - 1) do |i|
            if tab_name == component.get_title_at(i)
              component.set_selected_index(i)
            end
          end
        end
        sleep 1
      end

      def types(args)
        text = args[:text]
        component_name = args[:in]
        position = args[:at]


        view = @controller_context.instance_variable_get :@__view
        #main_component = view.instance_variable_get(:@main_view_component)

        component = view.instance_eval(component_name)

        text_index = case position
        when :beginning
          0
        when :end
          #
        end
        
        component.request_focus
        component.grab_focus
        component.caret_position = text_index if component.respond_to?(:caret_position=) && !text_index.nil?

        send_key_events component, text

        component.transfer_focus
        #push_robot_key text
        sleep 1
      end

    private

      
      def send_key_events(component, text)
        if component.kind_of?(javax.swing.JTextField) || component.kind_of?(javax.swing.JTextArea)
          puts ''
          puts "in send_key_event before assigning text"
          puts "text:#{text}"
          puts "component.text:#{component.text}"
          #TODO: These components do not work with dispatch event. 
          component.text = text.to_s #FIXME: this assignment is sometimes causing the stories to hang...
          puts "in send_key_event after assigning text"
        elsif component.kind_of? javax.swing.JComboBox
          component.selected_item = text
        elsif component.kind_of? javax::swing::JSpinner
          component.value = text.to_i
        else
          text.each_byte do |character|
            #char = character.chr
            #java.awt.event.KeyEvent::CHAR_UNDEFINED
            key_event = java.awt.event.KeyEvent.new(component, java.awt.event.KeyEvent::KEY_PRESSED, Time.now.to_i, 0, character, character)
    #            if component.kind_of?(javax.swing.JTextField) || component.kind_of?(javax.swing.JTextArea)
    #              event_queue = component.toolkit.system_event_queue
    #              event_queue.post_event key_event
    #            else
              component.dispatch_event key_event
    #            end
          end
        end
      end

      def push_robot_key(text)
        robot = java.awt.Robot.new
        robot.auto_delay = 0

        text.each_byte do |character|
          char = character.chr
          shift_pressed = char <= 'Z'

          case char
          when ' '
            char = 'SPACE'
          end

          key_code = java.awt.event.KeyEvent.const_get "VK_#{char.upcase}"
          robot.key_press java.awt.event.KeyEvent::VK_SHIFT if shift_pressed
          robot.key_press key_code
          robot.key_release key_code
          robot.key_release java.awt.event.KeyEvent::VK_SHIFT if shift_pressed
        end
        #give the robot a chance to type
        sleep 0.1
      end

      def get_window(window_name)
        @controller_context = "#{window_name}Controller".constantize.instance
        view = @controller_context.instance_variable_get(:@__view)
        view.instance_variable_get(:@main_view_component)
      end

      def get_controller(controller_name)
        controller_name = controller_name.split(' ').join
        "#{controller_name}Controller".constantize.instance
      end
    end
  end
end
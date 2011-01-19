require 'fileutils'

desc "ALL, CONTROLLER, VIEW, MODEL are valid options."
task 'generate'
rule(/^generate/) do |t|
  ARGV[1..-1].each do |generator_command|
    command, argument = generator_command.split("=")
    case command
    when "ALL"
      generate_tuple(argument)
    when "VIEW"
      generate_view(argument)
    when "CONTROLLER"
      generate_controller(argument)
    when "MODEL"
      generate_model(argument)
    else
      $stdout << "Unknown generate target #{argument}"
    end
  end
end

def generate_tuple(path)
  pwd = FileUtils.pwd
  generate_controller(path)
  FileUtils.cd(pwd)
  generate_model(path)
  FileUtils.cd(pwd)
  generate_view(path)
  FileUtils.cd(pwd)
  generate_ui(path)
end

def generate_controller(path)
  name = setup_directory(path)
  file_name = "#{name}_controller.rb"
  name = camelize(name)
  $stdout << "Generating controller #{name}Controller in file #{file_name}\n"
  File.open(file_name, "w") do |controller_file|
  controller_file << <<-ENDL
class #{name}Controller < ApplicationController
  set_model '#{name}Model'
  set_view '#{name}View'
  set_close_action :exit
end
  ENDL
  end
end

def generate_model path
  name = setup_directory path
  file_name = "#{name}_model.rb"
  name = camelize name
  $stdout << "Generating model #{name}Model in file #{file_name}\n"
  File.open(file_name, "w") do |model_file|
  model_file << <<-ENDL
class #{name}Model

end
  ENDL
  end
end

def generate_view path
  name = setup_directory path
  file_name = "#{name}_view.rb"
  name = camelize name
  $stdout << "Generating view #{name}View in file #{file_name}\n"
  File.open(file_name, "w") do |view_file|
  view_file << <<-ENDL
class #{name}View < ApplicationView
  set_java_class ''
end
  ENDL
  end
end


def generate_ui path
  name = setup_directory path
  file_name = "#{name}_controller.rb"
  name = camelize name
  $stdout << "Generating controller #{name}Controller in file #{file_name}\n"
  File.open(file_name, "w") do |ui_file|
  ui_file << <<-ENDL

$:.unshift 'lib/ruby'
require 'swingset'

include  Neurogami::SwingSet::Core
  
class #{name}Frame < Frame
  
  FRAME_WIDTH = 600
  FRAME_HEIGHT = 130

  LABEL_WIDTH = 400
  LABEL_HEIGHT = 60

  # Make sure our components are available!
  attr_accessor :default_button, :default_label, :menu_bar, :about_menu, :exit_menu

  def about_menu
    @about_menu
  end

  def initialize(*args)
    super
    self.minimum_width  = FRAME_WIDTH
    self.minimum_height = FRAME_HEIGHT
    set_up_components
  end

  def set_up_components
    component_panel = Panel.new

    # If we were clever we would define a method that took a  single hex value, like CSS.
    component_panel.background_color(255, 255, 255)
    component_panel.size(FRAME_WIDTH, FRAME_HEIGHT)

    # This code uses the MiG layout manager.
    # To learn more about MiGLayout, see:
    #     http://www.miglayout.com/
    component_panel.layout = Java::net::miginfocom::swing::MigLayout.new("wrap 2")

    @menu_bar = MenuBar.new do |menu_bar|
      @file_menu = Menu.new do |m|

        @exit_menu  = MenuItem.new do |mi|
          mi.name = 'exit_menu'
          mi.mnemonic= Monkeybars::Key.symbol_to_code(:VK_X)
          mi.text ="Exit"
        end

        m.name = 'file_menu'
        m.text ="File"
        m.add(@exit_menu)
      end

      @help_menu =  Menu.new do |m|
        @about_menu = MenuItem.new do |mi|
          mi.name = 'about_menu'
          mi.mnemonic= Monkeybars::Key.symbol_to_code(:VK_A)
          mi.text ="About"
        end

        m.name = 'help_menu'
        m.text = 'Help'
        m.add(@about_menu)
      end
    # Worth noting: you can add the menu item objects directly, which NetBeans doesn't seem to allow 
      menu_bar.add(@file_menu)
      menu_bar.add(@help_menu)
      set_jmenu_bar(menu_bar)
    end


    @default_label = Label.new do |l|
      # A nicer way to set fonts would be welcome
      l.font = java::awt.Font.new("Lucida Grande", 0, 18)
      l.minimum_dimensions(LABEL_WIDTH, LABEL_HEIGHT)
      l.text = "#{name} via Monkeybars rulez!"
    end

    # We need to set a name so that the controller can catch events from this button
    @default_button = Button.new do |b| 
      b.name = "default_button"
      b.text = "Click me!"
    end

    # Add components to panel
    component_panel.add @default_button, 'grow x'
    component_panel.add @default_label, "gap unrelated"
    add component_panel
  end

end
  ENDL
  end
end

def setup_directory path
  FileUtils.mkdir_p path.gsub("\\", "/")
  FileUtils.cd path
  path.split("/").last
end

def camelize(name, first_letter_in_uppercase = true)
  name = name.to_s
  if first_letter_in_uppercase
    name.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  else
    name[0..0] + camelize(name[1..-1])
  end
end
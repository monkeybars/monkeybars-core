require 'fileutils'

desc "ALL, CONTROLLER, VIEW, MODEL, UI are valid options."
task 'generate'
rule(/^generate/) do |t|
  ARGV[1..-1].each do |generator_command|
    command, argument = generator_command.split "="
    case command
    when "ALL"
      generate_tuple argument
    when "VIEW"
      generate_view argument
    when "CONTROLLER"
      generate_controller argument
    when "MODEL"
      generate_model argument
    when "UI"
      generate_ui argument

    else
      $stdout << "Unknown generate target #{argument}"
    end
  end
end

def generate_tuple path
  pwd = FileUtils.pwd
  generate_controller path

  FileUtils.cd pwd 
  generate_model path
  
  FileUtils.cd pwd
  generate_view path, from_all = true
  
  FileUtils.cd pwd
  generate_ui path

end

def generate_controller path
  name = setup_directory path
  file_name = "#{name}_controller.rb"
  name = camelize name
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

def generate_view path, from_all = false
  name = setup_directory path
  file_name = "#{name}_view.rb"
  cname = camelize name
  $stdout << "Generating view #{cname}View in file #{file_name}\n"
ui_require = if from_all
      "require '#{name}/#{name}_ui'"
               else
                 ""
  end
  java_class = if from_all
      "#{cname}Ui"
               else
                 "''"
  end
  File.open(file_name, "w") do |view_file|
  view_file << <<-ENDL
#{ui_require}

class #{cname}View < ApplicationView
  set_java_class #{java_class}
end
  ENDL
  end
end


def generate_ui path
  name = setup_directory path
  file_name = "#{name}_ui.rb"
  name = camelize name
  $stdout << "Generating ui #{name}Ui in file #{file_name}\n"
  File.open(file_name, "w") do |ui_file|
  ui_file << <<-ENDL

$:.unshift 'lib/ruby'
require 'swingset'

include  Neurogami::SwingSet::Core
  
class #{name}Ui < Frame
  include  Neurogami::SwingSet::MiG

  mig_layout

  FRAME_WIDTH  = 600
  FRAME_HEIGHT = 130

  LABEL_WIDTH  = 400
  LABEL_HEIGHT = 60

  # Make sure our components are available! 
  attr_accessor :default_button, :default_label

  def initialize *args
    super
    self.minimum_width  = FRAME_WIDTH
    self.minimum_height = FRAME_HEIGHT
    set_up_components
    default_close_operation = EXIT_ON_CLOSE 
  end

  def set_up_components
    component_panel = Panel.new

    # If we were clever we would define a method that took a  single hex value, like CSS.
    component_panel.background_color 255, 255, 255
    component_panel.size FRAME_WIDTH, FRAME_HEIGHT

    # This code uses the MiG layout manager.
    # To learn more about MiGLayout, see:
    #     http://www.miglayout.com/
    component_panel.layout = mig_layout "wrap 2"

    @default_label = Label.new do |l|
      l.font = Font.new "Lucida Grande", 0, 18
      l.minimum_dimensions LABEL_WIDTH, LABEL_HEIGHT
      l.text = "Neurogami::SwingSet rulez!"
    end

    @default_button = Button.new do |b|
      b.text = "Close"
    end





    # Add components to panel
    component_panel.add @default_label, "gap unrelated"
    component_panel.add @default_button, "gap unrelated"

    add component_panel

    @default_button.addActionListener lambda{ |e| default_button_clicked e}
  
  end

  def default_button_clicked event
    puts "Our button was clicked"
    java.lang.System.exit 0
  end

end




  ENDL
  end
end

def setup_directory path
  FileUtils.mkdir_p path.gsub "\\", "/"
  FileUtils.cd path
  path.split("/").last
end

def camelize name, first_letter_in_uppercase = true
  name = name.to_s
  if first_letter_in_uppercase
    name.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  else
    name[0..0] + camelize(name[1..-1])
  end
end

require 'spec'
$:.unshift(File.dirname(__FILE__))
require 'application_user'

steps_for :monkeybars do
  Given "the user is at the $main window" do |main_window_name|
    require "#{main_window_name}_controller"
    main_window_class = "#{main_window_name.capitalize}Controller".constantize
    @user = ApplicationUser.new(main_window_class.instance)
    main_window_class.instance.open
  end

  When "the user clicks the '$button_name' button" do |button_name|
    @user.clicks "#{button_name.downcase.gsub(' ', '_')}_button"
  end

  When "the user types the $subject '$text' in the $component" do |subject, text, component|
    instance_variable_set("@#{subject.downcase.gsub(' ', '_')}", text)
    @user.types :text => text, :in => component.downcase.gsub(' ', '_'), :at => :beginning
  end

  When "the user double clicks on row $row and column $column on the $component" do |column, row, component|
    @user.selects :table => component, :row => row, :column => column
    puts ''
    puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!NOT IMPLMENTED YET!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  end

  When "the user single clicks on row $row and column $column on the $component" do |column, row, component|
    @user.selects :table => component, :row => row, :column => column
  end

  Then "the user sees on row $row and column $column of the $component the data '$data'" do |row, column, component, data|
    @user.sees :table => component, :row => row, :column => column, :data => data
  end

  Then "the user sees the $subject '$text' in the $component" do |subject, text, component|
    instance_variable_set("@#{subject.downcase.gsub(' ', '_')}", text)
    component_name = component.downcase.gsub(' ', '_')
    component_eval =  case component_name
                      when /text_field$/
                        "#{component_name}.text"
                      when /combo_box$/
                        "#{component_name}.selected_item"
                      end
    @user.sees :value => text, :in => component_eval
  end

  Then "the user sees the '$window_name' window" do |window_name|
    @user.sees :window => window_name.gsub(' ', '')
  end

  Then "the user sees the '$panel_name' panel" do |panel_name|
    @user.sees :panel => panel_name.gsub(' ', '')
  end  
  
  When "the user clicks the '$tab_name' tab on the '$tabbed_pane' pane" do |tab_name, tabbed_pane|
    pane_name = tabbed_pane.gsub(' ', '_') +  "_tabbed_pane"
    pane_name.underscore
    pane_name.downcase!
    @user.selects :tab_name => tab_name, :tabbed_pane => pane_name
  end

  Then "the '$window' window is closed" do |window|
    @user.cannot_see :window => window
  end

  Then "the user closes the '$window' window" do |window|
    @user.closes :window => window
  end

  Then "the user exits the application" do
    #TODO: Find out what's lingering.
    @user.exits
  end
end

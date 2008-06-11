require 'user_controller'

class SortedUsersController < ApplicationController
  set_model 'SortedUsersModel'
  set_view 'SortedUsersView'
  set_close_action :exit
  
  def load
    @nested_user_controllers = []
    
    users = [{:first_name => "Billy", :last_name => "Bob", :age => 40},
             {:first_name => "Bobby", :last_name => "Joe", :age => 30},
             {:first_name => "Joe", :last_name => "Bob", :age => 20}
            ]
    @user_controllers = users.map do |user|
                          instance = UserController.create_instance
                          instance.open(user[:first_name], user[:last_name], user[:age])
                          instance
                        end
    sort_by :first_name
  end
  
  def sort_by_combo_box_action_performed
    view_model = view_state.first
    update_model(view_model, :sort_by_field)
    
    sort_by model.sort_by_field
  end
  
  def sort_by(field)
    @user_controllers.each do |user_controller|
      user_controller.set_sort_by_field(field)
    end
    
    @user_controllers.sort!
    
    # uncomment to see how the sort turned out
    #puts "sorted models:\n#{@user_controllers.map {|controller| controller.send(:model).inspect}.join("\n")}"
    
    remove_all_users
    
    @user_controllers.each do |user_controller|
      add_nested_controller(:users, user_controller)
      @nested_user_controllers << user_controller
    end
  end
  
  def remove_all_users
    signal :remove_all_users
    @nested_user_controllers.each do |user_controller|
      remove_nested_controller(:users, user_controller)
    end
    @nested_user_controllers.clear
  end
end

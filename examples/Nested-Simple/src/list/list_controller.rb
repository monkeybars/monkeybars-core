require 'search_controller'

class ListController < ApplicationController
  set_model 'ListModel'
  set_view 'ListView'
  set_close_action :exit
  
  LIST = ["Manos: The Hands of Fate",
          "Plan 9 from Outer Space",
          "Anus Magillicutty",
          "Monster A Go Go",
          "Ballistic: Ecks vs. Sever",
          "Santa Clause Conquers the Martians",
          "From Justin to Kelly",
          "An Alan Smithee Film: Burn Hollywood Burn",
          "Batman & Robin"].freeze
        
  def load
    search_controller = SearchController.instance
    search_controller.open
    add_nested_controller(:search, search_controller)
    
    search_controller.when_search_changed do |filter|
      filter_list(filter)
    end
  end
  
  def filter_list(filter)
    filtered_list = LIST.dup.delete_if {|element| element !~ Regexp.new(filter)}
    transfer[:list] = filtered_list
    update_view
  end
end

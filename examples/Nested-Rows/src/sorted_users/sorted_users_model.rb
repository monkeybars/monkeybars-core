class SortedUsersModel
  attr_accessor :sort_by_field
  
  def initialize
    @sort_by_field = :first_name
  end
end

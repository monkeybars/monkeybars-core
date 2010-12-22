class UserModel
  attr_accessor :first_name, :last_name, :age, :sort_by_field
  
  def initialize
    @first_name = ""
    @last_name = ""
    @age = 0
    @sort_by_field = :first_name
  end
  
  def <=>(other)
    send(@sort_by_field) <=> other.send(@sort_by_field)
  end
  
end

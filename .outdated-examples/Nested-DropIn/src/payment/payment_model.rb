class PaymentModel
  attr_accessor :same_address
  
  def initialize
    @same_address = false
  end
  
  def same_address?
    @same_address
  end
end

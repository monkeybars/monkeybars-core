class AddressModel
  attr_accessor :street_address1, :street_address2, :city, :state, :zip_code
  
  def initialize
    @street_address1 = ''
    @street_address2 = ''
    @city = ''
    @state = ''
    @zip_code = ''
  end
end

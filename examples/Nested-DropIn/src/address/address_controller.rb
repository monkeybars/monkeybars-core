class AddressController < ApplicationController
  set_model 'AddressModel'
  set_view 'AddressView'
  set_close_action :close
  
  def load
    signal :allow_editing
  end
  
  def set_editable(state)
    signal_name = state ? :allow_editing : :deny_editing
    signal signal_name
  end
  
  def use_address(foreign_address_model)
    update_model(foreign_address_model, :street_address1, :street_address2, :city, :state, :zip_code)
    update_view
  end
  
  def get_address
    update_model(view_state.first, :street_address1, :street_address2, :city, :state, :zip_code)
    model
  end
end

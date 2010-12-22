require 'address_controller'

class PaymentController < ApplicationController
  set_model 'PaymentModel'
  set_view 'PaymentView'
  set_close_action :exit
  
  def load
    @billing_address_controller = AddressController.create_instance
    add_nested_controller :billing, @billing_address_controller
    
    @shipping_address_controller = AddressController.create_instance
    add_nested_controller :shipping, @shipping_address_controller
    @shipping_address_controller.set_editable(false)
  end
  
  def unload
    AddressController.destroy_instance @billing_address_controller
    AddressController.destroy_instance @shipping_address_controller
  end
  
  def same_addess_check_box_action_performed
    use_same_address = view_state.first.same_address?
    @shipping_address_controller.set_editable(use_same_address)
    # not entirely necessary for the demo, but shows some separation of
    # nested controller instances. The model must be copied in order to be
    # seen on both.
    @shipping_address_controller.use_address(@billing_address_controller.get_address) unless use_same_address
  end
end

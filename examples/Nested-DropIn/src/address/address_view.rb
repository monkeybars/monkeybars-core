class AddressView < ApplicationView
  set_java_class 'address.AddressPanel'
  
  map :view => 'street_address1_text_field.text', :model => :street_address1
  map :view => 'street_address2_text_field.text', :model => :street_address2
  map :view => 'city_text_field.text', :model => :city
  map :view => 'state_combo_box.selected_item', :model => :state
  map :view => 'zip_code_text_field.text', :model => :zip_code
  
  define_signal :name => :allow_editing, :handler => :enable_fields
  define_signal :name => :deny_editing, :handler => :disable_fields
  
  def enable_fields(model, transfer)
    set_editable_fields(true)
  end
  
  def disable_fields(model, transfer)
    set_editable_fields(false)
  end
  
  def set_editable_fields(state)
    street_address1_text_field.enabled = state
    street_address2_text_field.enabled = state
    city_text_field.enabled = state
    state_combo_box.enabled = state
    zip_code_text_field.enabled = state
  end
end

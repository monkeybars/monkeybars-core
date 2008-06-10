class PaymentView < ApplicationView
  set_java_class 'payment.PaymentFrame'
  
  map :view => 'same_addess_check_box.selected', :model => :same_address
  
  nest :sub_view => :billing, :view => :billing_address_title_panel
  nest :sub_view => :shipping, :view => :shipping_address_title_panel
  
  def load
    # remove the place-holder design preview panels
    billing_address_title_panel.remove_all
    shipping_address_title_panel.remove_all
  end
end

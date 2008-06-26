require 'user'


steps_for :application do   
  Given "a closed call with the customer '$customer_name' and the machine numbered $machine_number and problem '$problem'" do |customer_name, machine_number, problem|
    customer = Customer.new(:name => customer_name)
    machine = Machine.new(:machine_number => machine_number, :customer => customer)
    Call.new(:customer => customer, :machine => machine, :technician => Technician.find_by_name("No Tech"), :work_order_number => 00000, :date => DateTime.now.to_s, :problem => problem, :status => Call::CLOSED).save!
  end

  Given "an open call with the customer '$customer_name' and the machine numbered $machine_number and problem '$problem'" do |customer_name, machine_number, problem|
    customer = Customer.new(:name => customer_name)
    customer.save!
    machine = Machine.new(:machine_number => machine_number, :customer => customer)
    machine.save!
    Call.new(:customer => customer, :machine => machine, :technician => Technician.find_by_name("No Tech"), :work_order_number => 00000, :date => DateTime.now.to_s, :problem => problem, :status => Call::OPEN).save!
  end

  Given "an existing customer named '$customer_name'" do |customer_name|
    Customer.new(:name => customer_name).save!
  end

  Given "an existing machine numbered '$machine_number' owned by '$customer_name'" do |machine_number, customer_name|
    customer = Customer.find_by_name customer_name
    customer = Customer.new(:name => customer_name) if customer.nil?
    Machine.new(:machine_number => machine_number, :customer => customer).save!
  end

  Given "an existing technician named '$tech_name'" do |tech_name|
    tech = Technician.find_by_name tech_name
    tech = Technician.new(:name => tech_name, :rate => 0) if tech.nil?
    tech.save!
  end

  Given "an existing technician named '$tech_name' with a rate of '$rate'" do |tech_name, rate|
    tech = Technician.find_by_name tech_name
    tech = Technician.new(:name => tech_name, :rate => rate) if tech.nil?
    tech.save!
  end

  Given "an existing part with a part number '$part_number'" do |part_number|
    part = Part.find_by_part_number part_number
    part = Part.new(:part_number => part_number, :description => '', :cost => 0, :price => 0) if part.nil?
    part.save!
  end

  Given "an existing part with a part number '$part_number' owned by '$tech_name' and a quantity of $quantity" do |part_number, tech_name, quantity|
    #part = Part.find_by_part_number part_number
    part = Part.new(:part_number => part_number, :description => '', :cost => 0, :price => 0) if part.nil?
    part.save!
    tech = Technician.find_by_name tech_name
    PartsPerTechnician.new(:technician => tech, :part => part, :quantity => quantity).save!
  end

  Then "a call is created" do
    Call.find(:first, :conditions => ['problem = ?', @problem]).should_not be_nil
  end

  Then "the call is assigned to the machine '$machine_number'" do |machine_number|
    call = Call.find :first
    machine = Machine.find_by_machine_number machine_number.to_i
    call.machine.should == machine
  end

  # TODO: Implement JOptionPane stuff
  Then "the user is prompted to create a new customer" do
    # I don't want pending, because pending == typo
  end

  Then "a customer is created" do
    Customer.find(:first, :conditions => ['name = ?', @customer_name]).should_not be_nil
  end
end
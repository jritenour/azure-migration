#  
# Get_Storage_Account
#
begin  
  # Method for logging  
  def log(level, message)  
    @method = 'create_environment'
    $evm.log(level, "#{@method} - #{message}")  
  end  
  
  # dump_root  
  def dump_root()  
    log(:info, "Root:<$evm.root> Begin $evm.root.attributes")  
    $evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}  
    log(:info, "Root:<$evm.root> End $evm.root.attributes")  
    log(:info, "")  
  end  
  
  # dump_root  
  # require necessary gems  
  require 'json'  
  require "active_support/core_ext"  
  require 'azure-armrest'
  
  # Azure Connection info is derived dynamically
@provider=$evm.vmdb(:ems).find_by_type("ManageIQ::Providers::Azure::CloudManager")
@client_id=@provider.authentication_userid
@client_key=@provider.authentication_password
@tenant_id=@provider.attributes['uid_ems']
@subscription_id=@provider.subscription
@location=@provider.attributes['provider_region']  

  #location = $evm_object['dialog_location']
  
  
  # Resource group name provided by dynamic dropdown
  dialog_field = $evm.object  
  attributes = $evm.root.attributes
  rg = attributes['dialog_rg_name']  
  sa = attributes['dialog_sa_name']  
  net= attributes['dialog_net_name']
  log(:info, "Listing Variables #{@tenant_id}, #{@client_id}, #{@client_key}")  
  
  log(:info, "Listing Variables #{sa}, #{rg}")  

  def get_connection()
    params = {
      :tenant_id=>@tenant_id,
      :client_id=>@client_id,
      :client_key=>@client_key,
      :subscription_id=>@subscription_id,
    }
    response=Azure::Armrest::ArmrestService.configure(params)
  end

  connection = get_connection()
  resource=Azure::Armrest::ResourceGroupService.new(connection)
  storage=Azure::Armrest::StorageAccountService.new(connection)
  network=Azure::Armrest::Network::VirtualNetworkService.new(connection)
  storage.api_version = '2015-06-15'
   
  log(:info, "Trying to create #{rg} resource group")
  resource.create(rg,@location)
  sleep (5)
   optionss = {
    :location   => @location, 
    :properties => {:accountType => 'Standard_LRS'},
    :tags       => {:my_company => true}
   }
  log(:info, "Trying to create #{sa} storage account in #{rg}") 
  storage.create(sa, rg, optionss)
  
  
  log(:info, "Trying to create #{net} in #{rg}")
  optionsn = {:location=>@location, :properties=>{:addressSpace=>{:addressPrefixes=>["10.3.0.0/16"]}}}
  network.create(net,rg,optionsn)

end  


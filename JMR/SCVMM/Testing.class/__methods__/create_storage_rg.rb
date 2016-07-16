#  
# Get_Storage_Account
#
begin  
  # Method for logging  
  def log(level, message)  
    @method = 'create_storage_rg'
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
  
  # Azure Connection info is provided in the schema  
  @tenant_id = nil || $evm.object['tenant_id']  
  @client_id = nil || $evm.object['client_id']  
  @client_key = nil|| $evm.object.decrypt('client_key')
  
  sa_name =  $evm.object['dialog_sa_name']  
  #location = $evm_object['dialog_location']
  
  
  # Resource group name provided by dynamic dropdown
  dialog_field = $evm.object  
  attributes = $evm.root.attributes
  rg = attributes['dialog_get_resource_group']  
  
  
  log(:info, "Listing Variables #{@tenant_id}, #{@client_id}, #{@client_key}")  
  
  log(:info, "Listing Variables #{sa_name}, #{rg}")  

  def get_storage_account()
    params = {
      :tenant_id=>@tenant_id,
      :client_id=>@client_id,
      :client_key=>@client_key,
    }
    response=Azure::Armrest::ArmrestService.configure(params)
  end

  storage = get_storage_account()
  sas=Azure::Armrest::StorageAccountService.new(storage)

  sas.api_version = '2015-06-15'

   options = {
    :location   => 'East US', 
    :properties => {:accountType => 'Standard_LRS'},
    :tags       => {:my_company => true}
   }
  sas.create(sa_name, rg, options)

end  


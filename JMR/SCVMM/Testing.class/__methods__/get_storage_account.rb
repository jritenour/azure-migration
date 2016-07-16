#  
# Get_Storage_Account
#  
begin  
  # Method for logging  
  def log(level, message)  
    @method = 'get_storage_account'
    $evm.log(level, "#{@method} - #{message}")  
  end  
  
  # dump_root  
  def dump_root()  
    log(:info, "Root:<$evm.root> Begin $evm.root.attributes")  
    $evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}  
    log(:info, "Root:<$evm.root> End $evm.root.attributes")  
    log(:info, "")  
  end  
  
   dump_root  
  # require necessary gems  
  require 'json'  
  require "active_support/core_ext"  
  require 'azure-armrest'
  
  # Azure Connection info is provided in the schema  
  @tenant_id = nil || $evm.object['tenant_id']  
  @client_id = nil || $evm.object['client_id']  
  @client_key = nil|| $evm.object.decrypt('client_key')

  
  # Resource group name provided by dynamic dropdown
  dialog_field = $evm.object  
  attributes = $evm.root.attributes
  rg = attributes['dialog_resource_group']  
  
  
  log(:info, "Listing Variables #{@tenant}, #{@client_id}, #{rg}")  
  

  def get_storage_account()
    params = {
      :tenant_id=>@tenant_id,
      :client_id=>@client_id,
      :client_key=>@client_key,
    }
    response=Azure::Armrest::ArmrestService.configure(params)
  end

  storage = get_storage_account()
#puts resources
  sas=Azure::Armrest::StorageAccountService.new(storage)
#puts rg.list
  $evm.log(:info, "Listing Resource Group: #{rg}")  
  sanames=sas.list("#{rg}").map {|x| [x["name"]]}
#puts names

$evm.log(:info, "Inspecting Resource Group  Names: #{sanames.inspect}")  


    # set the values  
    dialog_field['values'] = sanames
  
    # sort_by: value / description / none  
    dialog_field["sort_by"] = "description"  
    # sort_order: ascending / descending  
    dialog_field["sort_order"] = "ascending"  
    # data_type: string / integer  
    dialog_field["data_type"] = "string"  
    # required: true / false  
  dialog_field["required"] = "false"  
    log(:info, "Dynamic drop down values: #{dialog_field['values']}")  

end  


#  
# Get_Subnet
#  
begin  
  # Method for logging  
  def log(level, message)  
    @method = 'get_network'
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
  
  # Azure Connection info is derived from info in VMDB 
 @provider=$evm.vmdb(:ems).find_by_type("ManageIQ::Providers::Azure::CloudManager")
@client_id=@provider.authentication_userid
@client_key=@provider.authentication_password
@tenant_id=@provider.attributes['uid_ems']
@subscription_id=@provider.subscription

  
  # Resource group name provided by dynamic dropdown
  dialog_field = $evm.object  
  attributes = $evm.root.attributes
  rg = attributes['dialog_get_resource_group'] 
  vnet = attributes['dialog_get_network']  

  
  
  log(:info, "Listing Variables #{rg}, #{vnet}")  
  

  def get_subnet()
    params = {
      :tenant_id=>@tenant_id,
      :client_id=>@client_id,
      :client_key=>@client_key,
    }
    response=Azure::Armrest::ArmrestService.configure(params)
  end

  net = get_subnet()

  subnet = Azure::Armrest::Network::VirtualNetworkService.new(net) 
  getsubs=subnet.get( vnet, rg )
  subnames=getsubs.properties.subnets.map { |x| [x["id"], x["name"]]}

  $evm.log(:info, "Inspecting Subnet Names: #{subnames.inspect}")  


    # set the values  
  dialog_field['values'] = subnames.to_a
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

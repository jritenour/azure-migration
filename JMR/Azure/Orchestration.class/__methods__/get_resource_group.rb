#  
# Get_Resource_Group
#  
begin  
  # Method for logging  
  def log(level, message)  
    @method = 'get_resource_group'
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
  
@provider=$evm.vmdb(:ems).find_by_type("ManageIQ::Providers::Azure::CloudManager")
@client_id=@provider.authentication_userid
@client_key=@provider.authentication_password
@tenant_id=@provider.attributes['uid_ems']
@subscription_id=@provider.subscription
 
  
  log(:info, "Listing Variables #{@tenant}, #{@client_id}")  
  
  
  def get_resource_group()
    params = {
      :tenant_id=>@tenant_id,
      :client_id=>@client_id,
      :client_key=>@client_key,
      :subscription_id=>@subscription_id,
      :subscription_id=>@subscription_id,
    }
    response=Azure::Armrest::ArmrestService.configure(params)
  end

resources = get_resource_group()
#puts resources
rg=Azure::Armrest::ResourceGroupService.new(resources)
#puts rg.list
  names=rg.list.map{ |x| [x["name"],x["name"]] }
#puts names

$evm.log(:info, "Inspecting Resource Group  Names: #{names.inspect}")  

    dialog_field = $evm.object  
  
    # set the values  
    dialog_field['values'] = names.to_a
  
    # sort_by: value / description / none  
    dialog_field["sort_by"] = "description"  
    # sort_order: ascending / descending  
    dialog_field["sort_order"] = "ascending"  
    # data_type: string / integer  
    dialog_field["data_type"] = "string"  
    # required: true / false  
    dialog_field["required"] = "true"  
    log(:info, "Dynamic drop down values: #{dialog_field['values']}")  

end  


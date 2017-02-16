#  
# Create_public IP
#  
begin  
  # Method for logging  
  def log(level, message)  
    @method = 'create_pubip'
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
@location=@provider.attributes['provider_region']



  
  # Resource group name provided by dynamic dropdown
  dialog_field = $evm.object  
  attributes = $evm.root.attributes
  rg = attributes['dialog_get_resource_group']  
  
  ipname= nil || $evm.object['dialog_ipname'] 

  def get_ips()
    params = {
      :tenant_id=>@tenant_id,
      :client_id=>@client_id,
      :client_key=>@client_key,
      :subscription_id=>@subscription_id,
    }
    response=Azure::Armrest::ArmrestService.configure(params)
  end

  conf = get_ips()

  ips = Azure::Armrest::Network::IpAddressService.new(conf)
  
    options = {
  :location => @location,
  :properties => {
    :publicIPAddressVersion   => 'IPv4',
    :publicIPAllocationMethod => 'Dynamic',
    :idleTimeoutInMinutes     => 4,
    :dnsSettings => {
      :domainNameLabel => 'jmrtest2',
      :fqdn            => 'jmrtest2.eastus2.cloudapp.azure.com'
    }
  }
}

  ips.create(ipname, 'summit', options)

end  

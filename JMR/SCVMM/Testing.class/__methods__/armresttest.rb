begin


  # dump_root  
  def log(level, message)  
    @method = 'armresttest'
    $evm.log(level, "#{@method} - #{message}")  
  end  
  
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
  # Require what we need, setup your configuration information.
  require 'securerandom' # In the Ruby stdlib
  # F% info is provided in the schema  
  require 'json'
  require 'winrm'

  
  #variables
  attributes = $evm.root.attributes
  sa = attributes['dialog_get_storage_account']  
  vm_mig= $evm.root['vm'] 
  name = vm_mig.name
  host = vm_mig.host
  
  log(:info, "Preparing VM #{name} for migration.")  
    
  sleep (30)
  
  #added power stuff here
    unless vm_mig.power_state == 'off'
     vm_mig.stop
      log(:info, "Shutting down #{name}.")  
    vm_mig.refresh
    $evm.root['ae_result'] = 'retry'
    $evm.root['ae_retry_interval'] = '30.seconds'
  else
    $evm.root['ae_result'] = 'ok'
  end
 

log(:info, "Listing Variables #{name}, #{vm_mig.host}")  
log(:info, "Converting disk from VHDX to VHD.")  
  
script = <<SCRIPT
Get-VM -name #{name}|select-object VMiD|get-vhd|select-object path -expandproperty path|convert-vhd -destinationpath "C:\\#{name}.vhd"
Select-AzureRmProfile -Path "C:\\creds\\azure.txt"
Add-AzureRmVhd -Destination 'https://#{sa}.blob.core.windows.net/upload/#{name}.vhd' -LocalFilePath "C:\\#{name}.vhd" -ResourceGroupName "summit"
SCRIPT



url_params = {
  :ipaddress => host,
  :port      => 5985                # Default port 5985
}

connect_params = {
  :user         => host.authentication_userid,    # Example: domain\\user
  :pass         => host.authentication_password,
  :disable_sspi => true
}

url = "http://#{url_params[:ipaddress]}:#{url_params[:port]}/wsman"
winrm   = WinRM::WinRMWebService.new(url, :ssl, connect_params)
run_script=winrm.run_powershell_script(script)

        run_script[:data].each do | hash |
                hash.each do |k, v|
                end
        end

@provider=$evm.vmdb(:ems).find_by_type("ManageIQ::Providers::Azure::CloudManager")
@client_id=@provider.authentication_userid
@client_key=@provider.authentication_password
@tenant_id=@provider.attributes['uid_ems']
@subscription_id=@provider.subscription
    
    params = {
      :tenant_id=>@tenant_id,
      :client_id=>@client_id,
      :client_key=>@client_key,
    }
  
  #variables
  attributes = $evm.root.attributes
  sa = attributes['dialog_get_storage_account']  


conf = Azure::Armrest::ArmrestService.configure(params) # Your info here.


vms = Azure::Armrest::VirtualMachineService.new(conf)
nis = Azure::Armrest::Network::NetworkInterfaceService.new(conf)

nic = nis.get('nic2_eth0', 'summit')

src_uri = "https://#{sa}.blob.core.windows.net/upload/#{name}.vhd"
  vhd_uri = "http://#{sa}.blob.core.windows.net/upload/#{name}_" + SecureRandom.uuid + ".vhd"
options = 
{
  :name => name,
  :location => 'eastus2',
  :properties => {
    :hardwareProfile => { :vmSize => 'Basic_A2' },
    :osProfile => {
      :adminUserName => 'clouduser',
      :adminPassword => 'Mister2$',
      :computerName  => name
    },
    :storageProfile => {
      :osDisk => {
        :createOption => 'FromImage',
        :caching      => 'ReadWrite',
        :name         => name+'.vhd',
        :osType       => 'Linux',
        :image        => { :uri => src_uri }, # source
        :vhd          => { :uri => vhd_uri }  # target
      }
    },
    :networkProfile => {
      :networkInterfaces => [{:id => nic.id}]
    }
  }
}
  log(:info, "Listing Variables #{name}, #{vm_mig.host} #{vhd_uri}, #{vms}")  

  vms.create(name, 'summit', options)
end

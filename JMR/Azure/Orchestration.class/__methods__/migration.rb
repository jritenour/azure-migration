begin


  # dump_root  
  def log(level, message)  
    @method = 'migration'
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
  
   
  require "active_support/core_ext"  
  require 'azure-armrest'
  # Require what we need, setup your configuration information.
  require 'securerandom' # In the Ruby stdlib
  require 'winrm'
  require 'net/scp'

  
  #dialog variables
  attributes = $evm.root.attributes
  sa = attributes['dialog_get_storage_account']  
  rg = attributes['dialog_get_resource_group']  
  ipname = attributes['dialog_ipname']
  subnet = attributes['dialog_get_subnet']
  nicname = attributes['dialog_nicname']
  vmpass = attributes['dialog_vmpass']
  ostype = attributes['dialog_ostype']
  size = attributes['dialog_vmsize']

  #EVM variables from VMDB
  vm_mig= $evm.root['vm'] 
  name = vm_mig.name
  host = vm_mig.host

  vmwprov =  vm_mig.ext_management_system.hostname
  vmwuser =  vm_mig.ext_management_system.authentication_userid
  vmwpass =  vm_mig.ext_management_system.authentication_password
  
  #Schema Variables
  conversion_host = $evm.object['conversion_host']
  conversion_host_user   = $evm.object['conversion_host_user']
  conversion_host_pw   = $evm.object.decrypt('conversion_host_pw')
  conversion_host_path   = $evm.object['conversion_host_path']
  log(:info, "Preparing VM #{name} for migration.")  
  
  $evm.instantiate("/JMR/ConfigurationManagement/AnsibleTower/Operations/JobTemplate/seal_vm?job_template_name=seal_vm")
    
  sleep (120)
  
   # Shutdown system, as the azure deprovision process doesn't always do this.  
    unless vm_mig.power_state == 'off'
     vm_mig.stop
      log(:info, "Shutting down #{name}.")  
    vm_mig.refresh
    $evm.root['ae_result'] = 'retry'
    $evm.root['ae_retry_interval'] = '30.seconds'
    else
    $evm.root['ae_result'] = 'ok'
    end

   sleep (10)

  log(:info, "Listing Variables #{name}, #{vm_mig.host}, #{rg}, #{sa}")  

  # This section is for the hyper-v specific conversion/upload
  if vm_mig.ext_management_system.type.include? "Microsoft"
  log(:info, "Converting disk from VHDX to VHD.")  
  
  script = <<SCRIPT
Get-VM -name #{name}|select-object VMiD|get-vhd|select-object path -expandproperty path|convert-vhd -destinationpath "C:\\#{name}.vhd"
Select-AzureRmProfile -Path "C:\\creds\\azure.txt"
Add-AzureRmVhd -Destination 'https://#{sa}.blob.core.windows.net/upload/#{name}.vhd' -LocalFilePath "C:\\#{name}.vhd" -ResourceGroupName #{rg}
$result 
SCRIPT



url_params = {
  :ipaddress => host,
  :port      => 5985                # Default port 5985
}

connect_params = {
  :user         => host.authentication_userid,    # Example: domain\\user
  :pass         => host.authentication_password,
#  :disable_sspi => true
}

url = "http://#{url_params[:ipaddress]}:#{url_params[:port]}/wsman"
winrm   = WinRM::WinRMWebService.new(url, :negotiate, connect_params)
results=winrm.run_powershell_script(script)

errors = results[:data].collect { |d| d[:stderr] }.join
$evm.log("error", "WinRM returned stderr: #{errors}") unless errors.blank?

data = results[:data].collect { |d| d[:stdout] }.join
$evm.log("info", "WinRM returned hash: #{data}")

  elsif 
    #This block is vmware specifc
ps_script = <<PS_SCRIPT
$result = @{}

Import-Module 'C:\\Program Files\\Microsoft Virtual Machine Converter\\MvmcCmdlet.psd1'

$sourceUser= '#{vmwuser}'
$sourcePassword = ConvertTo-SecureString '#{vmwpass}' -AsPlainText -Force
$sourceCredential = New-Object PSCredential ($sourceUser, $sourcePassword)
$sourceConnection = New-MvmcSourceConnection -Server '#{vmwprov}' -SourceCredential $sourceCredential -verbose

$sourceVM = Get-MvmcSourceVirtualMachine -SourceConnection $sourceConnection -verbose | where {$_.Name -match "#{name}" }

$destinationLiteralPath = '#{conversion_host_path}' 
ConvertTo-MvmcVirtualHardDiskOvf -SourceConnection $sourceConnection -DestinationLiteralPath $destinationLiteralPath -GuestVmId $sourceVM.GuestVmId -vhdformat vhd
Select-AzureRmProfile -Path "C:\\creds\\azure.txt"
Add-AzureRmVhd -Destination 'https://#{sa}.blob.core.windows.net/upload/#{name}.vhd' -LocalFilePath "C:\\test\\#{name}\\disk-0.vhd" -ResourceGroupName #{rg}
$result 

$result

PS_SCRIPT

 
url_params = {
  :ipaddress => conversion_host,
  :port      => 5985                # Default port 5985
}

connect_params = {
  :user         => conversion_host_user,    # Example: domain\\user
  :pass         =>  conversion_host_pw,
#  :disable_sspi => true
}

url = "http://#{url_params[:ipaddress]}:#{url_params[:port]}/wsman"
winrm   = WinRM::WinRMWebService.new(url, :negotiate, connect_params)
results=winrm.run_powershell_script(ps_script)

errors = results[:data].collect { |d| d[:stderr] }.join
$evm.log("error", "WinRM returned stderr: #{errors}") unless errors.blank?

data = results[:data].collect { |d| d[:stdout] }.join
$evm.log("info", "WinRM returned hash: #{data}") 

  else 
  # if the source provider isn't Vmware or Hyper-V, drop out as it's not supported yet.  
  $evm.log("error", "This provider is not currently supported.")
  exit MIQ_STOP
end
  
@provider=$evm.vmdb(:ems).find_by_type("ManageIQ::Providers::Azure::CloudManager")
@client_id=@provider.authentication_userid
@client_key=@provider.authentication_password
@tenant_id=@provider.attributes['uid_ems']
@subscription_id=@provider.subscription
@location=@provider.attributes['provider_region']


    params = {
      :tenant_id=>@tenant_id,
      :client_id=>@client_id,
      :client_key=>@client_key,
      :subscription_id=>@subscription_id,
    }
  
  #variables
  attributes = $evm.root.attributes
  sa = attributes['dialog_get_storage_account']  
  

conf = Azure::Armrest::ArmrestService.configure(params) # Your info here.

ips = Azure::Armrest::Network::IpAddressService.new(conf)
  
    ipoptions = {
  :location => @location,
  :properties => {
    :publicIPAddressVersion   => 'IPv4',
    :publicIPAllocationMethod => 'Dynamic',
    :idleTimeoutInMinutes     => 4,
    :dnsSettings => {
      :domainNameLabel => name,
      :fqdn            => '#{name}.eastus2.cloudapp.azure.com'
    }
  }
}

ips.create(ipname, rg , ipoptions)
ipid=ips.get(ipname, rg)

vms = Azure::Armrest::VirtualMachineService.new(conf)

nis = Azure::Armrest::Network::NetworkInterfaceService.new(conf)

#nic = nis.get('nic2_eth0', rg)

nicoptions = {
  :name       => nicname,
  :location   => @location,
  :properties => {
    :ipConfigurations => [
      {
        :name => nicname,
        :properties => {
          :subnet          => {:id => subnet},
          :publicIPAddress => {:id => ipid.id}
        }
      }
    ]
  }
  }
  
nis.create(nicname, rg, nicoptions)
nic=nis.get(nicname,rg)

src_uri = "https://#{sa}.blob.core.windows.net/upload/#{name}.vhd"
  vhd_uri = "http://#{sa}.blob.core.windows.net/upload/#{name}_" + SecureRandom.uuid + ".vhd"
options = 
{
  :name => name,
  :location => @location,
  :properties => {
    :hardwareProfile => { :vmSize => size },
    :osProfile => {
      :adminUserName => 'clouduser',
      :adminPassword => vmpass,
      :computerName  => name
    },
    :storageProfile => {
      :osDisk => {
        :createOption => 'FromImage',
        :caching      => 'ReadWrite',
        :name         => name+'.vhd',
        :osType       => ostype,
        :image        => { :uri => src_uri }, # source
        :vhd          => { :uri => vhd_uri }  # target
      }
    },
    :networkProfile => {
      :networkInterfaces => [{:id => nic.id}]
    }
  }
}
log(:info, "Listing Variables #{name}, #{vm_mig.host} #{vhd_uri}, #{vms}, #{ipid.id}")  

 vms.create(name, rg, options)
end
exit MIQ_OK

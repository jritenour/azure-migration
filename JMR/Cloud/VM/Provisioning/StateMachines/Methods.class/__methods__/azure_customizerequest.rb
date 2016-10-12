#
# Description: This method is used to Customize the Amazon Provisioning Request
#

# Get provisioning object
prov = $evm.root["miq_provision"]
ws_values = prov.options.fetch(:ws_values, {})
if ws_values.has_key?(:ssh_public_key)
  ssh_public_key = find_object_for('SSHPublicKey', ws_values[:ssh_public_key])
  prov.set_ssh_public_key(ssh_public_key)
end
$evm.log("info", "Provisioning ID:<#{prov.id}> Provision Request ID:<#{prov.miq_provision_request.id}> Provision Type: <#{prov.type}>")

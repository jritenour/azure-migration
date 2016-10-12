###################################  
#  
# EVM Automate Method: Web_Item  
#  
# Inputs: $evm.root['service_template_provision_task'].dialog_options  
#  
###################################  
begin  
  @method = 'azure_configure'  
  $evm.log("info", "#{@method} - EVM Automate Method Started")  
  
  # Get the task object from root  
  service_template_provision_task = $evm.root['service_template_provision_task']  
  
  # Get destination service object  
  service = service_template_provision_task.destination  
  $evm.log("info","#{@method} - Detected Service:<#{service.name}> Id:<#{service.id}>")   
  
  
  # Get dialog options   
  dialog_options = service_template_provision_task.dialog_options  
  $evm.log("info","#{@method} - Inspecting Dialog Options:<#{dialog_options.inspect}>")   
  
  
  vm_name = dialog_options["dialog_vm_name"]  
  
  # Process Child Tasks  
  service_template_provision_task.miq_request_tasks.each do |child_task|  
    # Process grandchildren service options  
    unless child_task.miq_request_tasks.nil?  
      grandchild_tasks = child_task.miq_request_tasks  
      grandchild_tasks.each do |grandchild_task|  
        $evm.log("info","#{@method} -  Detected Grandchild Task ID:<#{grandchild_task.id}> Description:<#{grandchild_task.description}> source type:<#{grandchild_task.source_type}>")  
  
        # If child task is provisioning then apply tags and options  
        if grandchild_task.source_type == "template"  
          grandchild_task.set_option(:vm_target_name, vm_name)  
          grandchild_task.set_option(:vm_target_hostname, vm_name)  
        else  
          $evm.log("info","#{@method} - Invalid Source Type:<#{grandchild_task.source_type}>. Skipping task ID:<#{grandchild_task.id}>")   
        end # if grandchild_task.source_type  
      end # grandchild_tasks.each do  
    end # unless task.miq_request_tasks.nil?  
  end # service_template_provision_task.miq_request_tasks.each do  
  #  
  # Exit method  
  #  
  $evm.log("info", "#{@method} - EVM Automate Method Ended")  
  exit MIQ_OK  
  #  
  # Set Ruby rescue behavior  
  #  
rescue => err  
  $evm.log("error", "#{@method} - [#{err}]\n#{err.backtrace.join("\n")}")  
  exit MIQ_ABORT  
end  

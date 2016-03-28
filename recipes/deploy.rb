require 'json'

extra_vars = {}
app = node['custom_ansible']['app']
extra_vars['opsworks'] = node['opsworks']
extra_vars['ansible']  = node['ansible']
extra_vars['environment_variables'] = node['deploy'][app]['environment_variables'] 
extra_vars['repository'] = node['deploy'][app]['scm'] 
folder = node['ansible']['folder']

zippath = '/etc/opsworks-customs'
basepath  = '/etc/opsworks-customs/'+folder


execute "deploy" do
  command "ansible-playbook -i #{basepath}/inv #{basepath}/deploy.yml --extra-vars '#{extra_vars.to_json}'"
  only_if { ::File.exists?("#{basepath}/deploy.yml")}
  action :run
end

if ::File.exists?("#{basepath}/deploy.yml")
  Chef::Log.info("Log into #{node['opsworks']['instance']['private_ip']} and view /var/log/ansible.log to see the output of your ansible run")
else
  Chef::Log.info("No updates: #{basepath}/deploy.yml not found")
end

require 'json'
extra_vars = {}
extra_vars['opsworks'] = node['opsworks']
extra_vars['ansible']  = node['ansible']

Chef::Application.fatal!("'ansible['playbooks']' must be defined in custom json for the opsworks stack") if node['ansible'].nil? || node['ansible']['playbooks'].nil? || node['ansible']['playbooks'].empty?
Chef::Application.fatal!("'ansible['folder']' must be defined in custom json for the opsworks stack") if node['ansible'].nil? || node['ansible']['folder'].nil? || node['ansible']['folder'].empty?

apt_package 'ansible' do
  action :install
end


environment = node['ansible']['environment']
layer = node['opsworks']['instance']['layers'].first
playbooks = node['ansible']['playbooks']
folder = node['ansible']['folder']

zippath = '/etc/opsworks-customs'
basepath  = '/etc/opsworks-customs/'+folder

directory zippath do
  mode '0755'
  recursive true
  action :delete
end

directory zippath do
  mode '0755'
  recursive true
  action :create
end

remote_file '/etc/opsworks-customs/ansible.zip' do
  source playbooks
  mode '0755'
  action :create
end

execute 'extract_some_tar' do
  command 'unzip /etc/opsworks-customs/ansible.zip'
  cwd zippath
end

execute "setup" do
  command "ansible-playbook -i #{basepath}/inv #{basepath}/#{node['opsworks']['activity']}.yml --extra-vars '#{extra_vars.to_json}'"
  only_if { ::File.exists?("#{basepath}/#{node['opsworks']['activity']}.yml")}
  action :run
end

if ::File.exists?("#{basepath}/#{node['opsworks']['activity']}.yml")
  Chef::Log.info("Log into #{node['opsworks']['instance']['private_ip']} and view /var/log/ansible.log to see the output of your ansible run")
else
  Chef::Log.info("No updates: #{basepath}/#{node['opsworks']['activity']}.yml not found")
end

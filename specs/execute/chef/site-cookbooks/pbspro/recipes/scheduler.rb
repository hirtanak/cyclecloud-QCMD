# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#

pbsprover = node[:pbspro][:version]

package_name = "pbspro-server-#{pbsprover}.x86_64.rpm"

jetpack_download package_name do
  project 'QCMD'
end

yum_package package_name do
  source "#{node['jetpack']['downloads']}/#{package_name}"
  action :install
end

directory "#{node[:cyclecloud][:bootstrap]}/pbs" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

cookbook_file "/var/spool/pbs/doqmgr.sh" do
  source "doqmgr.sh"
  mode "0755"
  owner "root"
  group "root"
  action :create
end

cookbook_file "/var/spool/pbs/sched_priv/sched_config" do
  source "sched.config"
  owner "root"
  group "root"
  mode "0644"
end

service "pbs" do
  action [:enable, :start]
end

execute "serverconfig" do
  command "/var/spool/pbs/doqmgr.sh && touch /etc/qmgr.config"
  creates "/etc/qmgr.config"
  notifies :restart, 'service[pbs]', :delayed
end

include_recipe "pbspro::autostart"
include_recipe "pbspro::submit_hook"

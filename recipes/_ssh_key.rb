#
# Cookbook Name:: ossec
# Recipe:: _ssh_key
#
# Copyright 2016 Strata Consulting, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# conditionally add selinux_policy cookbook to manage selinux
case node['platform_family']
# only need on rhel family presently
when 'fedora', 'rhel'
  # amazon not supported
  include_recipe 'selinux_policy::install' unless node['platform'] == 'amazon'
end

include_recipe 'chef-vault'
ossec_key = chef_vault_item('ossec', 'ssh')

# create .ssh directory
directory "#{node['ossec']['dir']}/.ssh" do
  owner 'ossec'
  group 'ossec'
  mode '0750'
end

# ossec clients authorized_keys file
template "#{node['ossec']['dir']}/.ssh/authorized_keys" do
  source 'ssh_key.erb'
  owner 'ossec'
  group 'ossec'
  mode '0600'
  variables(key: ossec_key['pubkey'])
  notifies :addormodify, "selinux_policy_fcontext[#{node['ossec']['dir']}/.ssh/authorized_keys]", :immediately
  only_if { node['ossec']['mode'] == 'client' }
end

template "#{node['ossec']['dir']}/.ssh/id_rsa" do
  source 'ssh_key.erb'
  owner 'root'
  group 'ossec'
  mode '0600'
  variables(key: ossec_key['privkey'])
  only_if { node['ossec']['mode'] == 'server' }
end

# update selinux to permit read of ossec authorized_keys file
selinux_policy_fcontext "#{node['ossec']['dir']}/.ssh/authorized_keys" do
  secontext 'ssh_home_t'
  action :nothing
  only_if "which sestatus && sestatus | grep status | grep enabled"
end

#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Cookbook:: windows
# Recipe:: default
#
# Copyright:: 2011-2018, Chef Software, Inc.
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
#

Chef::Log.warn('The windows::default recipe has been deprecated. The gems previously installed in this recipe ship in the Chef MSI.')

#install dhcp
windows_feature 'ServicesForNFS-ClientOnly' do
  action :install
end
windows_feature 'ClientForNFS-Infrastructure' do
  action :install
end

#download and install
#windows_zipfile node['vim']['home'] do

#windows_zipfile node['vim']['home'] do
#  source node['vim']['url']
#  path node['vim']['home']
#  action :unzip
#  not_if {::File.exists?("#{node['vim']['version']}\\vim.exe")}
#end

# update path
#windows_path node['vim']['version'] do
#  action :add
#end

# create .vimrc
#template "#{ENV['USERPROFILE']}\\.vimrc" do
#     source "vimrc.erb"
#     variables({
#          :syntax => "syntax on",
#          :fileencodings => "utf-8,cp932",
#          :encoding => "cp932",
#          :backspace => "2",
#          :tabstop => "2",
#          :shiftwidth => "2",
#          :softtabstop => "0"
#     })
#     action :create
#end

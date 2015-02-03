# encoding: UTF-8

include_recipe 'garcon'
include_recipe 'garcon::development'
include_recipe 'test_fixtures::devreporter'
include_recipe 'test_fixtures::exceptioner'

template '/root/.bash_profile' do
  source 'bash_profile.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables path: ::File.join(node[:odsee][:install_dir], 'dsee7/bin')
  action :nothing
end.run_action(:create)

template '/etc/motd' do
  owner 'root'
  group 'root'
  mode 00644
  action :create
end

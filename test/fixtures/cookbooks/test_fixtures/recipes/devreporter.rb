# encoding: UTF-8

include_recipe 'chef_handler'

handler = ::File.join(node[:chef_handler][:handler_path], 'devreporter.rb')

cookbook_file handler do
  mode 00600
  action :create
end

chef_handler 'DevReporter' do
  source handler
  supports report: true
  action :enable
end

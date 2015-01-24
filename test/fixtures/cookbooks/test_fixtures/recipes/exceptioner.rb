# encoding: UTF-8

include_recipe 'chef_handler'

exceptioner = ::File.join(node[:chef_handler][:handler_path], 'passwords.rb')

cookbook_file exceptioner do
  owner 'root'
  group 'root'
  mode 00755
  action :create
end

chef_handler 'PasswordPooper' do
  source exceptioner
  supports :exception => true
  action :enable
end

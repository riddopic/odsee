# encoding: UTF-8

source 'https://supermarket.getchef.com'

metadata

group :integration do
  cookbook 'test_fixtures', path: 'test/fixtures/cookbooks/test_fixtures'
  cookbook 'sudo',          '>= 2.7.1'
  cookbook 'os-hardening',  '>= 1.2.0'
  cookbook 'ssh-hardening', '>= 1.0.3'
end

cookbook 'garcon', git: 'https://github.com/riddopic/garcon.git'

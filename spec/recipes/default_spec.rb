
require 'spec_helper'

describe 'odsee::default' do
  context 'basic system defaults' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        # server.create_data_bag('auth', get_databag_item('auth', 'data'))
      end.converge(described_recipe)
    end

  end
end


require 'chefspec'
require 'chefspec/berkshelf'
require 'chefspec/cacher'

# Require all our libraries
# Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

ChefSpec::Coverage.start! { add_filter 'odsee' }

RSpec.configure do |config|
  config.log_level = :fatal

  # Guard against people using deprecated RSpec syntax
  config.raise_errors_for_deprecations!

  # Why aren't these the defaults?
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # Set a default platform (this is overriden as needed)
  config.platform  = 'redhat'
  config.version   = '6.0'

  # Be random!
  config.order = 'random'
end

# require 'json'
# def get_databag_item(name, item)
#   filename = File.join('test/integration/data_bags', name, "#{item}.json")
#   { item => JSON.parse(IO.read(filename)) }
# end

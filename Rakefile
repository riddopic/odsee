# encoding: UTF-8

task default: 'test'

desc 'Run all tests except `kitchen`'
task test: [:yard, :rubocop, :foodcritic, :spec]

desc 'Run all tasks'
task all: [:yard, :rubocop, :foodcritic, :spec, 'kitchen:all']

desc 'Run kitchen integration tests'
task test: ['kitchen:all']

desc 'Build documentation'
task doc: [:readme, :yard]

desc 'Generate README.md from _README.md.erb'
task :readme do
  cmd = %w(knife cookbook doc -t _README.md.erb .)
  system(*cmd)
end

# measure YARD coverage
require 'yardstick/rake/measurement'
Yardstick::Rake::Measurement.new(:yardstick_measure) do |measurement|
  measurement.output = 'measurement/report.txt'
end

# verify YARD coverage
require 'yardstick/rake/verify'
Yardstick::Rake::Verify.new do |verify|
  verify.threshold = 100
end

require 'inch/rake'
Inch::Rake::Suggest.new

require 'yard'
YARD::Rake::YardocTask.new do |t|
  additional_docs = %w[ CHANGELOG.md LICENSE.md README.md ]
  t.files = ['**/*.rb', '-'] + additional_docs
  t.options = ['--readme=README.md', '--markup=markdown', '--verbose']
end

# rubocop style checker
require 'rubocop/rake_task'
RuboCop::RakeTask.new

# foodcritic chef lint
require 'foodcritic'
FoodCritic::Rake::LintTask.new do |t|
  t.options = { tags: ['~FC001'], fail_tags: ['any'], include: 'test/support/foodcritic/*', }
end

# chefspec unit tests
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:chefspec) do |t|
  t.rspec_opts = '--color'
end

# test-kitchen integration tests
begin
  require 'kitchen/rake_tasks'
  Kitchen::RakeTasks.new
rescue LoadError
  task('kitchen:all') { puts 'Unable to run `test-kitchen`' }
end

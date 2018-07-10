source ENV['GEM_SOURCE'] || 'https://rubygems.org'

puppetversion = ENV.key?('PUPPET_VERSION') ? ENV['PUPPET_VERSION'] : ['>= 3.3']
gem 'metadata-json-lint'
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper', '>= 1.2.0'
gem 'puppet-lint', '>= 1.0.0'
gem 'facter', '>= 1.7.0'
gem 'rspec-puppet'

# rspec must be v2 for ruby 1.8.7
if RUBY_VERSION >= '1.8.7' && RUBY_VERSION < '1.9'
  gem 'rspec', '~> 2.0'
  gem 'rake', '~> 10.0'
else
  # rubocop requires ruby >= 1.9
  gem 'rubocop'
  gem 'rubocop-rspec'
end

gem 'codecov'
gem 'simplecov', '~> 0'
#gem 'github_changelog_generator' if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Ve
#if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
#  gem 'rubocop', '< 0.50'
#  gem 'rubocop-rspec', '~> 1'
#end

# vim:filetype=ruby


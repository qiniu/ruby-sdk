# -*- encoding: utf-8 -*-

require File.expand_path('../lib/qiniu/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['why404','BluntBlade']
  gem.email         = ['sdk@qiniu.com']
  gem.description   = %q{Qiniu Resource (Cloud) Storage SDK for Ruby. See: http://developer.qiniu.com/docs/v6/sdk/ruby-sdk.html}
  gem.summary       = %q{Qiniu Resource (Cloud) Storage SDK for Ruby}
  gem.homepage      = 'https://github.com/qiniu/ruby-sdk'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features|examples)/})
  gem.name          = 'qiniu'
  gem.require_paths = ['lib']
  gem.version       = Qiniu::Version.to_s
  gem.license       = 'MIT'
  gem.required_ruby_version = '~> 2.1'

  # specify any dependencies here; for example:
  gem.add_development_dependency 'rake', '~> 12'
  gem.add_development_dependency 'rspec', '~> 3.5'
  gem.add_development_dependency 'webmock', '~> 2.3'
  gem.add_runtime_dependency 'json' 
  gem.add_runtime_dependency 'rest-client' 
  gem.add_runtime_dependency 'mime-types'
  gem.add_runtime_dependency 'jruby-openssl', '~> 0.7' if RUBY_PLATFORM == 'java'
end

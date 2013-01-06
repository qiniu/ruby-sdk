# -*- encoding: utf-8 -*-

require File.expand_path('../lib/qiniu/rs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["why404"]
  gem.email         = ["why404@gmail.com"]
  gem.description   = %q{Qiniu Resource (Cloud) Storage SDK for Ruby. See: http://docs.qiniutek.com/v3/sdk/ruby/}
  gem.summary       = %q{Qiniu Resource (Cloud) Storage SDK for Ruby}
  gem.homepage      = "https://github.com/qiniu/ruby-sdk"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "qiniu-rs"
  gem.require_paths = ["lib"]
  gem.version       = Qiniu::RS::Version.to_s

  # specify any dependencies here; for example:
  gem.add_development_dependency "rake", ">= 0.9"
  gem.add_development_dependency "rspec", ">= 2.11"
  gem.add_development_dependency "fakeweb", "~> 1.3"
  gem.add_runtime_dependency "json", "~> 1.7"
  gem.add_runtime_dependency "rest-client", "~> 1.6"
  gem.add_runtime_dependency "mime-types", "~> 1.19"
  gem.add_runtime_dependency "ruby-hmac", "~> 0.4"
  gem.add_runtime_dependency "jruby-openssl", "~> 0.7" if RUBY_PLATFORM == "java"
end

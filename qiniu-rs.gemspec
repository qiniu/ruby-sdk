# -*- encoding: utf-8 -*-

require File.expand_path('../lib/qiniu/rs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["why404"]
  gem.email         = ["why404@gmail.com"]
  gem.description   = %q{Qiniu Cloud Storage SDK for Ruby. See: http://docs.qiniutek.com/v1/sdk/ruby/}
  gem.summary       = %q{Qiniu Cloud Storage SDK for Ruby}
  gem.homepage      = "https://github.com/why404/qiniu-rs"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "qiniu-rs"
  gem.require_paths = ["lib"]
  gem.version       = Qiniu::RS::VERSION

  # specify any dependencies here; for example:
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "fakeweb"
  gem.add_runtime_dependency "rest-client"
  gem.add_runtime_dependency "mime-types"
end

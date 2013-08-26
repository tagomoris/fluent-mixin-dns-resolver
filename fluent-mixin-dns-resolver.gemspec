# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = "fluent-mixin-dns-resolver"
  gem.version       = "0.0.1"
  gem.authors       = ["TAGOMORI Satoshi"]
  gem.email         = ["tagomoris@gmail.com"]
  gem.description   = %q{fluentd mixin to add dns resolve/cache features}
  gem.summary       = %q{dns resolver mixin for fluentd plugin}
  gem.homepage      = "https://github.com/tagomoris/fluent-mixin-dns-resolver"
  gem.license       = "APLv2"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "rake"
  gem.add_runtime_dependency "fluentd"
end

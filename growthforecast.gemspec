# -*- encoding: utf-8 -*-
require File.expand_path('../lib/growthforecast/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["TAGOMORI Satoshi"]
  gem.email         = ["tagomoris@gmail.com"]
  gem.description   = %q{Client library and tool to update values, create/edit/delete graphs of GrowthForecast}
  gem.summary       = %q{A client library for GrowthForecast}
  gem.homepage      = "https://github.com/tagomoris/rb-growthforecast"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "growthforecast"
  gem.require_paths = ["lib"]
  gem.version       = GrowthForecast::VERSION

  gem.add_runtime_dependency "resolve-hostname"
end

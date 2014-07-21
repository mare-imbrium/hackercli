# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hackercli/version'

Gem::Specification.new do |spec|
  spec.name          = "hackercli"
  spec.version       = Hackercli::VERSION
  spec.authors       = ["kepler"]
  spec.email         = ["githubkepler.50s@gishpuppy.com"]
  spec.summary       = %q{uses Hacker News RSS and Reddit RSS to print titles and other info on command line}
  spec.description   = %q{uses Hacker News RSS and Reddit RSS to print titles and other info on command line}
  spec.homepage      = "https://github.com/mare-imbrium/hackercli"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end

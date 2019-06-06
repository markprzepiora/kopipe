# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kopipe/version'

Gem::Specification.new do |spec|
  spec.name          = "kopipe"
  spec.version       = Kopipe::VERSION
  spec.authors       = ["Mark Przepiora"]
  spec.email         = ["mark.przepiora@gmail.com"]
  spec.description   = %q{A flexible library for defining copier classes capable of effortlessly creating deep copies of your ActiveRecord objects.}
  spec.summary       = %q{Dead simple ActiveRecord object copying.}
  spec.homepage      = "https://github.com/markprzepiora/kopipe"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "with_model", "~> 1.2.2"
  spec.add_development_dependency "sqlite3", "~> 1.3.6"
end

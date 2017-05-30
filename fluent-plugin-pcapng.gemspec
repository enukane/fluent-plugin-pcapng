# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-pcapng"
  spec.version       = "0.1.1"
  spec.authors       = ["enukane"]
  spec.email         = ["enukane@glenda9.org"]
  spec.description   = %q{Fluentd plugin for tshark (pcapng) monitoring from specified interface}
  spec.summary       = %q{Fluentd input plugin for monitoring packets received in specified interface}
  spec.homepage      = "https://github.com/enukane/fluent-plugin-pcapng"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "fluentd", [">= 0.12.14", "< 2"]
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", ">= 0"
  spec.add_development_dependency "test-unit", "~> 3.0"
end

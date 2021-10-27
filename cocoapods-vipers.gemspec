# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-vipers/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-vipers'
  spec.version       = CocoapodsVipers::VERSION
  spec.authors       = ['fengjx']
  spec.email         = ['1026366384@qq.com']
  spec.description   = %q{tool to generate VIPER enum and medthod for Router}
  spec.summary       = %q{cocoapods-vipers generate VIPER enum and medthod for Router which is in HycanServices}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-vipers'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end

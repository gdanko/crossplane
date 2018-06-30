
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crossplane/version'

Gem::Specification.new do |spec|
  spec.name          = 'crossplane'
  spec.version       = Crossplane::VERSION
  spec.authors       = ['Gary Danko']
  spec.email         = ['gary_danko@intuit.com']
  spec.summary       = 'Reliable and fast NGINX configuration file parser and builder'
  spec.description   = 'Quick and reliable way to convert NGINX configurations into JSON and back.'
  spec.homepage      = 'https://github.com/gdanko/crossplane'
  spec.license       = 'GPL-2.0'

  spec.files = [
    'bin/crossplane',
    'lib/crossplane/analyzer.rb',
    'lib/crossplane/builder.rb',
    'lib/crossplane/cli.rb',
    'lib/crossplane/config.rb',
    'lib/crossplane/errors.rb',
    'lib/crossplane/globals.rb',
    'lib/crossplane/lexer.rb',
    'lib/crossplane/parser.rb',
    'lib/crossplane/utils.rb',
    'lib/crossplane/version.rb',
  ]

  spec.executables   = 'crossplane'
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.3'

  spec.add_development_dependency 'bundler', '~> 2.2', '>= 2.2.3'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_runtime_dependency 'thor', '~> 0.19', '~> 0.19.1'
end

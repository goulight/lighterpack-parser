# frozen_string_literal: true

require_relative 'lib/lighterpack_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'lighterpack-parser'
  spec.version       = LighterpackParser::VERSION
  spec.authors       = ['Packlista Team']
  spec.email         = ['team@packlista.com']

  spec.summary       = 'Parser for Lighterpack lists'
  spec.description   = 'Parse Lighterpack HTML to extract list data including categories, items, weights, and metadata'
  spec.homepage      = 'https://github.com/packlista/lighterpack-parser'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'spec/**/*', '*.md', '*.gemspec']
  spec.require_paths = ['lib']

  spec.add_dependency 'nokogiri', '~> 1.15'
  spec.add_dependency 'httparty', '~> 0.21'

  spec.add_development_dependency 'rspec', '~> 3.12'
end

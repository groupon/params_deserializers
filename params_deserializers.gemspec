$:.push File.expand_path('../lib', __FILE__)
require 'params_deserializers/version'

Gem::Specification.new do |s|
  s.name        = 'params_deserializers'
  s.version     = ParamsDeserializers::VERSION
  s.summary     = 'Deserializers for Rails params'
  s.description = 'Modeled after active_model_serializers, this gem allows you to create deserializer classes for incoming Rails parameters.'
  s.authors     = ['Jesse Pinho', 'Trek Glowacki', 'Jim Challenger']
  s.email       = ['jessepinho@groupon.com']
  s.homepage    = 'https://github.groupondev.com/jepinho/params-deserializers'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']

  s.add_dependency 'rails', '~> 4.2.1'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'guard-rspec'
end

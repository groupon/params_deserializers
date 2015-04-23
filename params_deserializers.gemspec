Gem::Specification.new do |s|
  s.name        = 'params_deserializers'
  s.version     = '0.0.0'
  s.date        = '2015-03-31'
  s.summary     = 'Deserializers for Rails params'
  s.description = 'Modeled after active_model_serializers, this gem allows you to create deserializer classes for incoming Rails parameters.'
  s.authors     = ['Trek Glowacki', 'Jesse Pinho', 'Jim Challenger']
  s.email       = 'jessepinho@groupon.com'
  s.files       = ['lib/params_deserializers.rb']
  s.homepage    = 'https://github.groupondev.com/jepinho/params-deserializers'
  s.license     = 'MIT'

  s.add_dependency 'activesupport'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'guard-rspec'
end

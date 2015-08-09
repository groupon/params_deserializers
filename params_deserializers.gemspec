# Copyright (c) 2015, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

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
  s.license     = 'BSD-3-Clause'

  s.files = Dir['lib/**/*', 'Rakefile', 'README.md']

  s.add_dependency 'activesupport', '>= 3.2.16', '< 5.0'

  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rails', '>= 4.2'
  s.add_development_dependency 'rspec-rails'
end

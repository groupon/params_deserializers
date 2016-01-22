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

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'

class ParamsDeserializer
  class MissingRootKeyError < StandardError; end
  class InvalidKeyError < StandardError; end

  def initialize(params)
    @params = params
    verify_root_key_exists
    verify_valid_keys
  end

  def deserialize
    deserialized_params = {}
    self.class.attrs.unignored.each do |attr|
      next unless instance_exec(&attr.present_if)
      deserialized_params[attr.name] = self.send(attr.name)
    end
    format_keys(deserialized_params).with_indifferent_access
  end

  private

  attr_reader :params

  def format_key(key)
    case self.class.key_format
    when :snake_case then key.to_s.underscore.to_sym
    when :camel_case then key.to_s.camelize.to_sym
    when :lower_camel then key.to_s.camelize(:lower).to_sym
    else key
    end
  end

  def format_keys(hash)
    hash = Hash[hash.map { |k, v| [format_key(k), v] }] if self.class.key_format
    optionally_include_root_key(hash)
  end

  def optionally_include_root_key(hash)
    return hash unless self.class.include_root_key?
    { format_key(self.class.root_key) => hash }
  end

  def params_root
    return @params_root if @params_root

    if self.class.root_key
      @params_root = params[self.class.root_key]
    else
      @params_root = params
    end
  end

  def verify_root_key_exists
    if self.class.root_key && !params.has_key?(self.class.root_key)
      raise MissingRootKeyError, "Root key #{self.class.root_key} is missing from params."
    end
  end

  def verify_valid_keys
    invalid_params = params_root.symbolize_keys.keys - self.class.attrs.map(&:original_name)
    if self.class.strict_mode && !invalid_params.empty?
      raise InvalidKeyError, "Invalid keys in params: #{invalid_params.map(&:inspect).join(",")}."
    end
  end

  class << self
    attr_reader :root_key
    attr_accessor :key_format
    attr_accessor :strict_mode
    alias_method :format_keys, :key_format=
    alias_method :strict, :strict_mode=

    def inherited(subclass)
      subclass.instance_variable_set(:@attrs, @attrs)
      subclass.instance_variable_set(:@discard_root_key, @discard_root_key)
      subclass.instance_variable_set(:@key_format, @key_format)
      subclass.instance_variable_set(:@root_key, @root_key)
      subclass.instance_variable_set(:@strict_mode, @strict_mode)
    end

    def deserialize(params)
      new(params).deserialize
    end

    def attrs
      @attrs ||= AttributeCollection.new
    end

    def attribute(attr, options = {})
      define_getter_method(attr, options) do
        params_root[attr]
      end
    end

    def ignore(*param_names)
      param_names.each do |param_name|
        attrs << Attribute.new(param_name, ignored: true)
      end
    end

    def attributes(*args)
      args.each do |attr|
        attribute(attr)
      end
    end

    def has_many(attr, options = {})
      define_getter_method(attr, options) do
        return params_root[attr] unless options[:deserializer]

        params_root[attr].map do |relation|
          options[:deserializer].new(relation).deserialize
        end if params_root[attr].is_a?(Array)
      end
    end

    def root(key, options = {})
      @root_key = key
      @discard_root_key = options[:discard]
    end

    def include_root_key?
      @root_key && !@discard_root_key
    end

    private

    def define_getter_method(attr, options = {}, &block)
      options[:rename_to] ||= attr
      attrs << Attribute.new(attr, options)
      define_method(options[:rename_to], &block) unless method_defined?(options[:rename_to])
    end
  end
end

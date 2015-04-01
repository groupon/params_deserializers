require 'plissken'
require 'awrence'

class ParamsDeserializer
  def initialize(params)
    @params = params
  end

  def deserialize
    deserialized_params = {}
    self.class.attrs.each do |attr|
      deserialized_params[attr] = self.send(attr)
    end
    deserialized_params.send(self.class.key_format)
  end

  class << self
    def attrs
      @attrs ||= []
    end

    def attributes(*args)
      args.each do |attr|
        attrs << attr
        define_method(attr) do
          @params[attr]
        end
      end
    end

    def format_keys format
      @key_format = case format
      when :snake_case then :to_snake_keys
      when :camel_case then :to_camel_keys
      when :lower_camel then :to_camelback_keys
      end
    end

    def key_format
      @key_format || :to_hash
    end

    def has_many(attr, options = {})
      options[:to] ||= attr
      attrs << options[:to]
      define_method(options[:to]) do
        return @params[attr] unless options[:deserializer]

        @params[attr].map do |relation|
          options[:deserializer].new(relation).deserialize
        end
      end
    end
  end

  private
  attr_reader :params
end

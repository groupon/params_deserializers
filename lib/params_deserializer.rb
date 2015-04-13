require 'plissken'
require 'awrence'

class ParamsDeserializer
  def initialize(params)
    @params = params
  end

  def deserialize
    deserialized_params = {}
    self.class.attrs.each do |attr|
      next unless instance_exec(&attr[:present_if])
      deserialized_params[attr[:final_key]] = self.send(attr[:final_key])
    end
    include_root(deserialized_params).send(self.class.key_format)
  end

  private

  attr_reader :params

  def params_root
    @params_root ||= case self.class.root_key
                     when nil then params
                     else params[self.class.root_key]
                     end
  end

  def include_root(params)
    if self.class.root_key && !self.class.discard_root_key
      { self.class.root_key => params }
    else
      params
    end
  end

  class << self
    attr_reader :root_key, :discard_root_key

    def attrs
      @attrs ||= []
    end

    def attribute(attr, options = {})
      options[:rename_to] ||= attr
      add_attr(attr, options)
      define_method(options[:rename_to]) do
        params_root[attr]
      end
    end

    def attributes(*args)
      args.each do |attr|
        attribute(attr)
      end
    end

    def format_keys(format)
      @key_format = case format
      when :snake_case then :to_snake_keys
      when :camel_case then :to_camel_keys
      when :lower_camel then :to_camelback_keys
      end
    end

    def has_many(attr, options = {})
      options[:rename_to] ||= attr
      add_attr(attr, options)
      define_method(options[:rename_to]) do
        return params_root[attr] unless options[:each_deserializer]

        params_root[attr].map do |relation|
          options[:each_deserializer].new(relation).deserialize
        end
      end
    end

    def key_format
      @key_format || :to_hash
    end

    def root(key, options = {})
      @root_key = key
      @discard_root_key = options[:discard]
    end

    private

    def add_attr(attr, options = {})
      options[:rename_to] ||= attr
      options[:present_if] ||= -> { params_root.has_key?(attr) }
      attrs << { original_key: attr,
                 final_key: options[:rename_to],
                 present_if: options[:present_if] }
    end
  end
end

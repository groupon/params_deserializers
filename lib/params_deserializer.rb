class ParamsDeserializer
  def initialize(params)
    @params = params
  end

  def deserialize
    deserialized_params = {}
    self.class.attrs.each do |attr|
      next unless instance_exec(&attr.present_if)
      deserialized_params[attr.name] = self.send(attr.name)
    end
    optionally_include_root_key(deserialized_params).send(self.class.key_format)
  end

  private

  attr_reader :params

  def params_root
    @params_root ||= case self.class.root_key
                     when nil then params
                     else params[self.class.root_key]
                     end
  end

  def optionally_include_root_key(deserialized_params)
    return deserialized_params unless self.class.include_root_key?
    { self.class.root_key => deserialized_params }
  end

  class << self
    attr_reader :root_key

    def attrs
      @attrs ||= AttributeCollection.new
    end

    def attribute(attr, options = {})
      define_getter_method(attr, options) do
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
      define_getter_method(attr, options) do
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

    def include_root_key?
      @root_key && !@discard_root_key
    end

    private

    def define_getter_method(attr, options = {}, &block)
      options[:rename_to] ||= attr
      attrs << Attribute.new(attr, options[:rename_to], options[:present_if])
      define_method(options[:rename_to], &block) unless method_defined?(options[:rename_to])
    end
  end
end

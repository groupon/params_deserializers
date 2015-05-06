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
    @params_root ||= case self.class.root_key
                     when nil then params
                     else params[self.class.root_key]
                     end
  end

  class << self
    attr_reader :root_key
    attr_accessor :key_format
    alias_method :format_keys, :key_format=

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
      attrs << Attribute.new(attr, options[:rename_to], options[:present_if])
      define_method(options[:rename_to], &block) unless method_defined?(options[:rename_to])
    end
  end
end

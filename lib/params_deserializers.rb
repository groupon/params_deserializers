class V5::Deserializer
  def initialize(params)
    @params = params
    @deserialized_params = {}
  end

  def deserialize
    self.class.attrs.each do |attr|
      @deserialized_params[attr] = self.send(attr)
    end

    @deserialized_params
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

    def has_many(attr, options)
      method_name = options[:to]
      attrs << method_name
      define_method(method_name) do
        @params[attr]
      end
    end
  end
end

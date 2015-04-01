class ParamsDeserializer
  def initialize(params)
    @params = params
  end

  def deserialize
    deserialized_params = {}
    self.class.attrs.each do |attr|
      deserialized_params[attr] = self.send(attr)
    end
    deserialized_params
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

    def has_many(attr, options = {})
      options[:to] ||= attr
      attrs << options[:to]
      define_method(options[:to]) do
        @params[attr]
      end
    end
  end
end
